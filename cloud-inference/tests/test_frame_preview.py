import sys
import unittest
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from main import MAX_PREVIEW_BYTES, _encode_frame_preview


class FramePreviewTests(unittest.TestCase):
    def test_preview_is_decodable_and_within_firestore_field_budget(self):
        rng = np.random.default_rng(42)
        frame = rng.integers(0, 256, (1080, 1920, 3), dtype=np.uint8)

        encoded = _encode_frame_preview(frame)
        decoded = cv2.imdecode(
            np.frombuffer(encoded, dtype=np.uint8),
            cv2.IMREAD_COLOR,
        )

        self.assertLessEqual(len(encoded), MAX_PREVIEW_BYTES)
        self.assertIsNotNone(decoded)
        self.assertLessEqual(decoded.shape[1], 640)
        self.assertAlmostEqual(
            decoded.shape[1] / decoded.shape[0],
            1920 / 1080,
            places=2,
        )


if __name__ == "__main__":
    unittest.main()
