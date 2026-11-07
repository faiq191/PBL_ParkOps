import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from detection_logic import normalize_class_name, summarize_detections


class DetectionLogicTests(unittest.TestCase):
    def test_normalizes_model_labels(self):
        self.assertEqual(normalize_class_name(" Empty_Space "), "empty space")

    def test_counts_vehicle_and_empty_space_classes(self):
        counts = summarize_detections(
            [
                {"className": "car"},
                {"className": "motorcycle"},
                {"className": "empty_space"},
                {"className": "occupied"},
            ],
            vehicle_labels={"car", "motorcycle"},
            empty_space_labels={"empty space"},
        )

        self.assertEqual(counts, {"vehicleCount": 2, "emptySpaceCount": 1})


if __name__ == "__main__":
    unittest.main()
