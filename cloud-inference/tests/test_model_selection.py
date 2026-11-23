import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_local import _choose_model


class ModelSelectionTests(unittest.TestCase):
    def test_selects_numbered_model_and_retries_invalid_choice(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            models_directory = Path(temporary_directory)
            model_names = [
                "parkops_gray.pt",
                "parkops_normal.pt",
                "parkops_polinema_merged.pt",
            ]
            for name in model_names:
                (models_directory / name).touch()

            with (
                patch("builtins.input", side_effect=["0", "2"]),
                patch("builtins.print") as print_mock,
            ):
                selected = _choose_model(models_directory)

        self.assertEqual(selected.name, "parkops_normal.pt")
        self.assertEqual(
            [call.args[0] for call in print_mock.call_args_list],
            [
                "Choose a YOLO model:",
                "1. parkops_gray.pt",
                "2. parkops_normal.pt",
                "3. parkops_polinema_merged.pt",
                "Invalid choice. Enter a number from 1 to 3.",
            ],
        )

    def test_fails_clearly_when_model_directory_is_empty(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            with self.assertRaisesRegex(FileNotFoundError, "No .pt model files"):
                _choose_model(Path(temporary_directory))


if __name__ == "__main__":
    unittest.main()
