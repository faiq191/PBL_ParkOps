import logging
import os
import threading
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

import cv2
import firebase_admin
import numpy as np
from flask import Flask, jsonify
from google.cloud import firestore, storage
from ultralytics import YOLO

from detection_logic import summarize_detections


CAMERA_ID = "opentopia-17916"
CAMERA_TITLE = "Parking with Apartment View - Osaka"
DEFAULT_CAMERA_URL = "http://118.243.55.168:84/VIDEO.CGI"
MODEL_PATH = Path("/tmp/best.pt")
MAX_FRAME_BYTES = 8 * 1024 * 1024

app = Flask(__name__)
_model = None
_model_lock = threading.Lock()
_firestore_client = None


def _configured_names(environment_key: str, defaults: str) -> set[str]:
    raw_names = os.getenv(environment_key, defaults)
    return {name.strip() for name in raw_names.split(",") if name.strip()}


def _download_model() -> Path:
    model_uri = os.getenv("MODEL_GCS_URI", "")
    if not model_uri.startswith("gs://"):
        raise ValueError("MODEL_GCS_URI must be a gs:// URI to best.pt")

    bucket_name, _, object_name = model_uri[5:].partition("/")
    if not bucket_name or not object_name:
        raise ValueError("MODEL_GCS_URI must include a bucket and object path")

    storage.Client().bucket(bucket_name).blob(object_name).download_to_filename(
        str(MODEL_PATH)
    )
    return MODEL_PATH


def _get_model() -> YOLO:
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:
                _model = YOLO(str(_download_model()))
    return _model


def _read_jpeg_frame(camera_url: str) -> np.ndarray:
    request = Request(camera_url, headers={"User-Agent": "ParkOps/1.0"})
    buffer = bytearray()
    total_bytes = 0

    with urlopen(request, timeout=15) as response:
        while total_bytes < MAX_FRAME_BYTES:
            chunk = response.read(64 * 1024)
            if not chunk:
                break
            total_bytes += len(chunk)
            buffer.extend(chunk)
            start = buffer.find(b"\xff\xd8")
            if start >= 0:
                end = buffer.find(b"\xff\xd9", start + 2)
                if end >= 0:
                    encoded = np.frombuffer(buffer[start : end + 2], dtype=np.uint8)
                    frame = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
                    if frame is not None:
                        return frame
                    raise RuntimeError("The camera returned an unreadable JPEG frame")
                if start:
                    del buffer[:start]

    raise RuntimeError("No complete JPEG frame received from the camera")


def _detect(frame: np.ndarray) -> tuple[dict, list[dict]]:
    prediction = _get_model().predict(
        source=frame,
        conf=float(os.getenv("CONFIDENCE_THRESHOLD", "0.25")),
        verbose=False,
    )[0]
    detections = []
    names = prediction.names

    if prediction.boxes is not None:
        for box in prediction.boxes:
            class_id = int(box.cls.item())
            coordinates = [round(float(value), 2) for value in box.xyxy[0].tolist()]
            detections.append(
                {
                    "className": str(names[class_id]),
                    "classId": class_id,
                    "confidence": round(float(box.conf.item()), 4),
                    "box": coordinates,
                }
            )

    counts = summarize_detections(
        detections,
        vehicle_labels=_configured_names(
            "VEHICLE_CLASS_NAMES", "car,vehicle,truck,bus,motorcycle"
        ),
        empty_space_labels=_configured_names(
            "EMPTY_SPACE_CLASS_NAMES",
            "empty,empty space,empty slot,empty parking space,empty bay,free space,vacant",
        ),
    )
    return counts, detections[:100]


def run_inference() -> dict:
    global _firestore_client
    frame = _read_jpeg_frame(os.getenv("CAMERA_URL", DEFAULT_CAMERA_URL))
    counts, detections = _detect(frame)
    processed_at = datetime.now(timezone.utc)
    result = {
        "cameraId": CAMERA_ID,
        "cameraTitle": CAMERA_TITLE,
        "vehicleCount": counts["vehicleCount"],
        "emptySpaceCount": counts["emptySpaceCount"],
        "detections": detections,
        "frameWidth": int(frame.shape[1]),
        "frameHeight": int(frame.shape[0]),
        "processedAt": processed_at,
        "modelObject": os.getenv("MODEL_GCS_URI", ""),
    }

    if _firestore_client is None:
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app()
        _firestore_client = firestore.client()
    _firestore_client.collection("camera_inference").document(CAMERA_ID).set(result)
    return {**result, "processedAt": processed_at.isoformat()}


@app.get("/healthz")
def health_check():
    return jsonify({"status": "ok"})


@app.post("/infer")
def infer():
    if not os.getenv("MODEL_GCS_URI"):
        return jsonify({"error": "MODEL_GCS_URI is not configured"}), 503

    try:
        result = run_inference()
    except (OSError, RuntimeError, ValueError) as error:
        logging.exception("Camera inference failed")
        return jsonify({"error": str(error)}), 502

    return jsonify(result)
