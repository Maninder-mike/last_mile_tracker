# SD Card Logger for offline data backup
from machine import Pin, SPI
import os
import time


class SDLogger:
    """Log sensor data to SD card as CSV backup"""

    # ESP32-C6 SPI pins for SD card (SPI 2)
    # Check your board docs! Often:
    PIN_CS = 5
    PIN_SCK = 2
    PIN_MOSI = 3
    PIN_MISO = 4

    def __init__(self):
        self._mounted = False
        try:
            # Requires 'sdcard.py' driver to be present in lib/
            # We assume it's there or user has frozen bytecode
            import sdcard

            self._spi = SPI(
                2,
                sck=Pin(self.PIN_SCK),
                mosi=Pin(self.PIN_MOSI),
                miso=Pin(self.PIN_MISO),
            )
            self._sd = sdcard.SDCard(self._spi, Pin(self.PIN_CS))

            # Check if already mounted
            try:
                os.stat("/sd")
            except OSError:
                os.mount(self._sd, "/sd")

            self._mounted = True
            self._ensure_log_file()
        except Exception as e:
            print(f"SD card init failed (missing sdcard.py?): {e}")

    def _ensure_log_file(self):
        if not self._mounted:
            return
        try:
            os.stat("/sd/sensor_log.csv")
        except OSError:
            with open("/sd/sensor_log.csv", "w") as f:
                # Version 2 Header
                f.write("timestamp,lat,lon,speed,temp,shock,battery_mv,int_temp\n")

    def log(self, data: dict):
        """Append sensor reading to CSV"""
        if not self._mounted:
            return
        try:
            ts = time.time()
            line = f"{ts},{data['lat']},{data['lon']},{data['speed']},{data['temp']},{data['shock']},{data.get('battery_mv', 0)},{data.get('internal_temp', 0)}\n"
            with open("/sd/sensor_log.csv", "a") as f:
                f.write(line)
        except Exception as e:
            print(f"SD write error: {e}")

    @property
    def is_mounted(self) -> bool:
        return self._mounted
