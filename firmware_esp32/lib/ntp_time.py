import ntptime
import time
from machine import RTC
from lib.logger import Logger
from typing import Any


class NTPClient:
    def __init__(self, config: Any) -> None:
        self.config = config
        self.rtc = RTC()
        self.last_sync = 0.0
        self.sync_interval = 3600 * 24  # Sync daily

    def sync(self) -> bool:
        """Synchronize time with NTP server"""
        try:
            # Set host from config or default
            ntptime.host = self.config.get("ntp_server") or "pool.ntp.org"

            Logger.log(f"NTP: Syncing with {ntptime.host}...")
            ntptime.settime()  # Sets internal RTC to UTC

            self.last_sync = time.time()
            now = time.localtime()
            Logger.log(
                f"NTP: Time synced: {now[0]}-{now[1]:02d}-{now[2]:02d} {now[3]:02d}:{now[4]:02d}:{now[5]:02d} UTC"
            )
            return True
        except Exception as e:
            Logger.log(f"NTP: Sync failed: {e}")
            return False

    def get_timestamp(self) -> float:
        """Return current timestamp (UTC) or 0 if not synced"""
        # We assume 2024+ (1704067200) to be valid
        now = time.time()
        if now < 1704067200:
            return 0.0
        return now

    def is_synced(self) -> bool:
        return self.get_timestamp() > 0

