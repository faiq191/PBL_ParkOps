import os
import threading
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

import cv2
import firebase_admin
from firebase_admin import firestore as admin_firestore
import numpy as np
from ultralytics import YOLO

from detection_logic import summarize_detections


CAMERA_ID = "opentopia-17916"
CAMERA_TITLE = "Parking with Apartment View - Osaka"
DEFAULT_CAMERA_URL = "http://118.243.55.168:84/VIDEO.CGI"
DEFAULT_PROJECT_ID = "pblparkopsfaiq"
DEFAULT_MODEL_PATH = Path(__file__).parent / "models" / "best.pt"
MAX_FRAME_BYTES = 8 * 1024 * 1024
MAX_PREVIEW_BYTES = 512 * 1024
MAX_PREVIEW_WIDTH = 640

_model = None
_model_lock = threading.Lock()
_firestore_client = None


def _configured_names(environment_key: str, defaults: str) -> set[str]:
    raw_names = os.getenv(environment_key, defaults)
    return {name.strip() for name in raw_names.split(",") if name.strip()}


def _get_model() -> YOLO:
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:
                model_path = Path(
                    os.getenv("MODEL_PATH", str(DEFAULT_MODEL_PATH))
                ).expanduser()
                if not model_path.is_file():
                    raise FileNotFoundError(
                        f"Model weights not found: {model_path}. "
                        "Pass --model with the path to best.pt."
                    )
                _model = YOLO(str(model_path))
    return _model


def get_model_classes() -> dict[int, str]:
    names = _get_model().names
    if isinstance(names, dict):
        return {int(class_id): str(name) for class_id, name in names.items()}
    return {class_id: str(name) for class_id, name in enumerate(names)}


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


def _encode_frame_preview(frame: np.ndarray) -> bytes:
    height, width = frame.shape[:2]
    scale = min(1.0, MAX_PREVIEW_WIDTH / width)
    preview = (
        cv2.resize(
            frame,
            (round(width * scale), round(height * scale)),
            interpolation=cv2.INTER_AREA,
        )
        if scale < 1
        else frame
    )

    while True:
        for quality in (65, 50, 35):
            encoded_ok, encoded = cv2.imencode(
                ".jpg",
                preview,
                [cv2.IMWRITE_JPEG_QUALITY, quality],
            )
            if not encoded_ok:
                raise RuntimeError("Could not encode the camera frame preview")
            if encoded.nbytes <= MAX_PREVIEW_BYTES:
                return encoded.tobytes()

        preview_height, preview_width = preview.shape[:2]
        if preview_width <= 160 or preview_height <= 120:
            break
        preview = cv2.resize(
            preview,
            (max(1, round(preview_width * 0.75)), max(1, round(preview_height * 0.75))),
            interpolation=cv2.INTER_AREA,
        )

    raise RuntimeError("Camera frame preview exceeds the Firestore size limit")


def _detect(frame: np.ndarray) -> tuple[dict, list[dict]]:
    prediction = _get_model().predict(
        source=frame,
        device=os.getenv("YOLO_DEVICE", "0"),
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
    frame_preview = _encode_frame_preview(frame)
    processed_at = datetime.now(timezone.utc)
    result = {
        "cameraId": CAMERA_ID,
        "cameraTitle": CAMERA_TITLE,
        "vehicleCount": counts["vehicleCount"],
        "emptySpaceCount": counts["emptySpaceCount"],
        "detections": detections,
        "frameWidth": int(frame.shape[1]),
        "frameHeight": int(frame.shape[0]),
        "framePreview": frame_preview,
        "processedAt": processed_at,
        "inferenceDevice": str(_get_model().predictor.device),
        "modelName": Path(
            os.getenv("MODEL_PATH", str(DEFAULT_MODEL_PATH))
        ).expanduser().name,
    }

    if _firestore_client is None:
        try:
            firebase_app = firebase_admin.get_app()
        except ValueError:
            firebase_app = firebase_admin.initialize_app(
                options={
                    "projectId": os.getenv(
                        "GOOGLE_CLOUD_PROJECT", DEFAULT_PROJECT_ID
                    )
                }
            )
        _firestore_client = admin_firestore.client(app=firebase_app)
    _firestore_client.collection("camera_inference").document(CAMERA_ID).set(result)
    return {**result, "processedAt": processed_at.isoformat()}
