from typing import Any, Dict

class Diagnostics:
    SAVE_THRESHOLD = 5  # Save every 5 increments

    def __init__(self, config: Any) -> None:
        self.config = config
        self.counters: Dict[str, int] = {
            "reboots": 0,
            "i2c_errors": 0,
            "ble_disconnects": 0,
            "gps_lost": 0,
            "watchdog_resets": 0,
            "sensor_read_fails": 0,
            "http_post_ok": 0,
            "http_post_fail": 0,
            "sd_write_fail": 0,
            "exceptions": 0,
        }
        self._unsaved_count = 0
        self._load()

    def _load(self) -> None:

        saved = self.config.get("diagnostics")
        if saved:
            for k, v in saved.items():
                self.counters[k] = v

    def flush(self) -> None:
        """Manually flush diagnostics to storage"""
        if self._unsaved_count > 0:

            self.config.set("diagnostics", self.counters)
            self._unsaved_count = 0
            print("Diagnostics: Flushed to config.")

    def increment(self, metric: str) -> None:
        if metric not in self.counters:
            self.counters[metric] = 0

        self.counters[metric] += 1
        self._unsaved_count += 1

        print(f"Diagnostics: {metric} -> {self.counters[metric]}")

        if self._unsaved_count >= self.SAVE_THRESHOLD:
            self.flush()

    def get_report(self) -> Dict[str, int]:
        return self.counters

