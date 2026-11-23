import argparse
import logging
import os
import time
from pathlib import Path

from main import (
    CAMERA_ID,
    CAMERA_SOURCES,
    CameraFrameError,
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
        help=(
            "Path to model weights; choose interactively from "
            "cloud-inference/models if omitted"
        ),
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


def _choose_model(models_directory: Path) -> Path:
    models = sorted(
        models_directory.glob("*.pt"),
        key=lambda path: path.name.casefold(),
    )
    if not models:
        raise FileNotFoundError(f"No .pt model files found in {models_directory}")

    print("Choose a YOLO model:")
    for number, model in enumerate(models, start=1):
        print(f"{number}. {model.name}")

    while True:
        try:
            choice = input(f"Enter a number (1-{len(models)}): ").strip()
        except EOFError as error:
            raise RuntimeError(
                "Model selection needs interactive input; "
                "pass --model with a path."
            ) from error
        if choice.isdigit() and 1 <= int(choice) <= len(models):
            return models[int(choice) - 1]
        print(f"Invalid choice. Enter a number from 1 to {len(models)}.")


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    args = _arguments()
    model_path = (
        args.model.expanduser()
        if args.model is not None
        else _choose_model(DEFAULT_MODEL_PATH.parent)
    ).resolve()
    if not model_path.is_file():
        raise FileNotFoundError(f"Model weights not found: {model_path}")

    os.environ["MODEL_PATH"] = str(model_path)
    os.environ["GOOGLE_CLOUD_PROJECT"] = args.project
    os.environ["CONFIDENCE_THRESHOLD"] = str(args.confidence)
    os.environ["YOLO_DEVICE"] = args.device
    if args.show_classes:
        for class_id, label in get_model_classes().items():
            print(f"{class_id}: {label}")
        return

    while True:
        for camera in CAMERA_SOURCES:
            camera_url = (
                args.camera_url
                if camera.camera_id == CAMERA_ID
                else camera.stream_url
            )
            try:
                result = run_inference(
                    camera_id=camera.camera_id,
                    camera_title=camera.title,
                    camera_url=camera_url,
                )
            except CameraFrameError as error:
                logging.error("%s", error)
                continue
            logging.info(
                "Updated %s: %s vehicles, %s empty spaces (%s detections)",
                camera.camera_id,
                result["vehicleCount"],
                result["emptySpaceCount"],
                len(result["detections"]),
            )
            logging.info("Inference device: %s", result["inferenceDevice"])
        if args.once:
            return
        logging.info(
            "Next pass over all cameras in %s seconds; press Ctrl+C to stop.",
            args.interval,
        )
        time.sleep(args.interval)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Stopped by user.")
