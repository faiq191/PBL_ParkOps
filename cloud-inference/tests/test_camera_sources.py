import argparse
import sys
import unittest
from pathlib import Path
from unittest.mock import call, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_local
from main import CAMERA_ID, CAMERA_SOURCES, DEFAULT_CAMERA_URL


class CameraSourceTests(unittest.TestCase):
    def test_all_three_opentopia_parking_cameras_are_configured(self):
        self.assertEqual(
            [camera.camera_id for camera in CAMERA_SOURCES],
            ["opentopia-17916", "opentopia-17921", "opentopia-17917"],
        )
        self.assertEqual(
            [camera.stream_url for camera in CAMERA_SOURCES],
            [
                "http://118.243.55.168:84/VIDEO.CGI",
                "http://119.242.68.125:84/VIDEO.CGI",
                "http://125.193.245.91:84/VIDEO.CGI",
            ],
        )

    def test_worker_passes_each_configured_camera_to_inference(self):
        args = argparse.Namespace(
            model=Path(__file__),
            camera_url=DEFAULT_CAMERA_URL,
            project="pblparkopsfaiq",
            confidence=0.25,
            device="0",
            vehicle_labels="car",
            empty_space_labels="empty",
            show_classes=False,
            once=True,
            interval=30,
        )
        results = [
            {
                "vehicleCount": 1,
                "emptySpaceCount": 2,
                "detections": [],
                "inferenceDevice": "cpu",
            }
            for _ in CAMERA_SOURCES
        ]

        with (
            patch.object(run_local, "_arguments", return_value=args),
            patch.object(run_local, "run_inference", side_effect=results) as infer,
        ):
            run_local.main()

        self.assertEqual(
            infer.call_args_list,
            [
                call(
                    camera_id=camera.camera_id,
                    camera_title=camera.title,
                    camera_url=(
                        DEFAULT_CAMERA_URL
                        if camera.camera_id == CAMERA_ID
                        else camera.stream_url
                    ),
                )
                for camera in CAMERA_SOURCES
            ],
        )


if __name__ == "__main__":
    unittest.main()
