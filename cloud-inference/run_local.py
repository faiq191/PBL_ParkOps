import argparse
import logging
import os
import time
from pathlib import Path

from main import (
    DEFAULT_CAMERA_URL,
    DEFAULT_MODEL_PATH,
    DEFAULT_PROJECT_ID,
    get_model_classes,
    run_inference,
)


def _positive_integer(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return parsed


def _confidence(value: str) -> float:
    parsed = float(value)
    if not 0 <= parsed <= 1:
        raise argparse.ArgumentTypeError("must be between 0 and 1")
    return parsed


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run ParkOps camera inference on this computer."
    )
    parser.add_argument(
        "--model",
        type=Path,
        default=DEFAULT_MODEL_PATH,
        help="Path to best.pt (default: cloud-inference/models/best.pt)",
    )
    parser.add_argument(
        "--camera-url",
        default=DEFAULT_CAMERA_URL,
        help="Camera MJPEG URL",
    )
    parser.add_argument(
        "--project",
        default=DEFAULT_PROJECT_ID,
        help="Firebase/Google Cloud project ID",
    )
    parser.add_argument(
        "--interval",
        type=_positive_integer,
        default=30,
        help="Seconds between inferences (default: 30)",
    )
    parser.add_argument(
        "--confidence",
        type=_confidence,
        default=0.25,
        help="YOLO confidence threshold from 0 to 1 (default: 0.25)",
    )
    parser.add_argument(
        "--device",
        default="0",
        help="Inference device: 0 selects the first CUDA GPU; use cpu to force CPU.",
    )
    parser.add_argument(
        "--vehicle-labels",
        default="car,vehicle,truck,bus,motorcycle",
        help="Comma-separated model labels to count as vehicles",
    )
    parser.add_argument(
        "--empty-space-labels",
        default=(
            "empty,empty space,empty slot,empty parking space,"
            "empty bay,free space,vacant"
        ),
        help="Comma-separated model labels to count as empty spaces",
    )
    parser.add_argument(
        "--show-classes",
        action="store_true",
        help="Load the model, print its class labels, and exit",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run one inference and exit",
    )
    return parser.parse_args()


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    args = _arguments()
    model_path = args.model.expanduser().resolve()
    if not model_path.is_file():
        raise FileNotFoundError(f"Model weights not found: {model_path}")

    os.environ["MODEL_PATH"] = str(model_path)
    os.environ["CAMERA_URL"] = args.camera_url
    os.environ["GOOGLE_CLOUD_PROJECT"] = args.project
    os.environ["CONFIDENCE_THRESHOLD"] = str(args.confidence)
    os.environ["YOLO_DEVICE"] = args.device
    os.environ["VEHICLE_CLASS_NAMES"] = args.vehicle_labels
    os.environ["EMPTY_SPACE_CLASS_NAMES"] = args.empty_space_labels

    if args.show_classes:
        for class_id, label in get_model_classes().items():
            print(f"{class_id}: {label}")
        return

    while True:
        result = run_inference()
        logging.info(
            "Updated Firestore: %s vehicles, %s empty spaces (%s detections)",
            result["vehicleCount"],
            result["emptySpaceCount"],
            len(result["detections"]),
        )
        logging.info("Inference device: %s", result["inferenceDevice"])
        if args.once:
            return
        logging.info("Next inference in %s seconds; press Ctrl+C to stop.", args.interval)
        time.sleep(args.interval)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Stopped by user.")
