import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from detection_logic import summarize_detections


class DetectionLogicTests(unittest.TestCase):
    def test_counts_busy_and_empty_classes_only(self):
        counts = summarize_detections(
            [
                {"className": "busy"},
                {"className": "BUSY"},
                {"className": " busy "},
                {"className": "empty"},
                {"className": "EMPTY"},
                {"className": " empty "},
                {"className": "occupied"},
                {"className": "car"},
            ]
        )

        self.assertEqual(counts, {"vehicleCount": 1, "emptySpaceCount": 1})


if __name__ == "__main__":
    unittest.main()
