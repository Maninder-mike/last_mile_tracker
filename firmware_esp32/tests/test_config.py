import sys
import unittest
from unittest.mock import mock_open, patch

# Ensure we can import from lib
sys.path.append("firmware_esp32")

from lib.config import Config


class TestConfig(unittest.TestCase):
    def setUp(self) -> None:
        # Reset any singleton state if necessary, or just create fresh instances
        pass

    def test_defaults(self) -> None:
        """Test that a new Config object has default values."""
        # Mock load to prevent file I/O during init
        with patch.object(Config, "load"):
            cfg = Config()
            self.assertEqual(cfg.get("wifi_ssid"), "")
            self.assertEqual(cfg.get("shock_threshold"), 500)
            self.assertEqual(cfg.get("firmware_version"), "0.0.2")

    def test_load_existing_config(self) -> None:
        """Test loading configuration from a JSON file."""
        mock_data = '{"wifi_ssid": "test_net", "shock_threshold": 800}'
        with patch("builtins.open", mock_open(read_data=mock_data)):
            with patch("json.load") as mock_json_load:
                mock_json_load.return_value = {"wifi_ssid": "test_net", "shock_threshold": 800}
                cfg = Config()
                # Config calls load() in __init__
                self.assertEqual(cfg.get("wifi_ssid"), "test_net")
                self.assertEqual(cfg.get("shock_threshold"), 800)

    def test_save_config(self) -> None:
        """Test saving configuration to a JSON file."""
        with patch.object(Config, "load"):
            cfg = Config()
            cfg.set("wifi_ssid", "new_net")

            m = mock_open()
            with patch("builtins.open", m):
                cfg.save()

            m.assert_called_with("config.json", "w")
            # We can't easily check the json.dump content with simple mock_open,
            # but we verified the file was opened for writing.


if __name__ == "__main__":
    unittest.main()
