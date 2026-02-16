import math
from machine import Pin, I2C, UART, ADC
import onewire
import ds18x20
import time
import esp32


class MPU6050:
    """MPU-6050 6-axis Accelerometer/Gyroscope driver"""

    MPU_ADDR = 0x68
    PWR_MGMT_1 = 0x6B
    ACCEL_XOUT_H = 0x3B

    def __init__(self, i2c: I2C):
        self._i2c = i2c
        try:
            self._i2c.writeto_mem(self.MPU_ADDR, self.PWR_MGMT_1, bytes([0]))
        except OSError:
            print("MPU6050 not found")

    def read_accel(self) -> tuple:
        """Read accelerometer X, Y, Z in g-force"""
        try:
            data = self._i2c.readfrom_mem(self.MPU_ADDR, self.ACCEL_XOUT_H, 6)
            ax = self._bytes_to_int(data[0], data[1]) / 16384.0
            ay = self._bytes_to_int(data[2], data[3]) / 16384.0
            az = self._bytes_to_int(data[4], data[5]) / 16384.0
            return (ax, ay, az)
        except OSError:
            return (0.0, 0.0, 1.0)

    def get_shock_value(self) -> int:
        """Calculate shock magnitude (0-1000 scale) - Optimized"""
        ax, ay, az = self.read_accel()
        # Fast magnitude approximation: max(|x|, |y|, |z|) + 0.5 * mid + 0.25 * min
        # Or just use math.sqrt if hardware floating point is available (ESP32-C6 has it)
        # However, avoiding pow(x, 2) is still better.
        magnitude = math.sqrt(ax * ax + ay * ay + az * az)
        shock = abs(magnitude - 1.0) * 500
        return min(int(shock), 1000)

    def _bytes_to_int(self, high: int, low: int) -> int:
        value = (high << 8) | low
        if value >= 0x8000:
            value -= 0x10000
        return value


class SensorHub:
    """Unified sensor interface - Non-blocking ready"""

    def __init__(self, diagnostics=None):
        self.diagnostics = diagnostics

        try:
            self._i2c = I2C(0, scl=Pin(7), sda=Pin(6), freq=400000)
            self._mpu = MPU6050(self._i2c)
        except Exception as e:
            print(f"MPU6050 init failed: {e}")
            self._mpu = None
            if self.diagnostics:
                self.diagnostics.increment("i2c_errors")

        try:
            # Enable internal pull-up (~45k) for resistor-less operation
            self._ow_pin = Pin(4, Pin.IN, Pin.PULL_UP)
            self._ow = onewire.OneWire(self._ow_pin)
            self._ds = ds18x20.DS18X20(self._ow)
            self._temp_roms = self._ds.scan()
            if self._temp_roms:
                self._ds.convert_temp()  # Initial trigger
        except Exception as e:
            print(f"DS18B20 init failed: {e}")
            self._temp_roms = []
            if self.diagnostics:
                self.diagnostics.increment("onewire_errors")

        self._gps_uart = UART(1, baudrate=115200, tx=21, rx=20)
        self._last_gps = {"lat": 0.0, "lon": 0.0, "speed": 0.0, "fix": False}
        self._last_temps = {}  # ROM ID: Value
        self._last_temp_read = 0

        # Pre-allocated result dictionary to avoid heap allocation in main loop (Rule 3)
        self._read_result = {
            "lat": 0.0,
            "lon": 0.0,
            "speed": 0.0,
            "gps_fix": False,
            "temp": 0.0,
            "all_temps": self._last_temps,
            "shock": 0,
            "battery_mv": 0,
            "internal_temp": 0.0,
        }

        self._init_battery()

    def _init_battery(self):
        try:
            # GPIO 2 is often used for battery Sense on generic boards,
            # but user should verify. Using GPIO 0 as placeholder or config.
            # Ideally this comes from config.
            bat_pin = 2
            if self.diagnostics and self.diagnostics.config:
                bat_pin = self.diagnostics.config.get("battery_pin") or 2

            self._bat_adc = ADC(Pin(bat_pin))
            self._bat_adc.atten(ADC.ATTN_11DB)  # Full range: 3.3v
        except Exception as e:
            print(f"Battery init failed: {e}")
            self._bat_adc = None

    def read_battery_mv(self) -> int:
        if not self._bat_adc:
            return 0
        try:
            # Raw 0-4095.
            # Voltage divider logic usually needed.
            # Assuming 100k/100k divider -> x2 multiplier.
            # 3.3V ref.
            # raw / 4095 * 3300 * 2
            raw = self._bat_adc.read()
            mv = (raw * 3300 * 2) // 4095
            return int(mv)
        except Exception:
            return 0

    def read_internal_c(self) -> float:
        try:
            f = esp32.raw_temperature()
            return (f - 32) / 1.8
        except Exception:
            return 0.0

    async def read_all(self) -> dict:
        """Async-ready unified read with multi-sensor support"""
        self._read_gps()

        # Temperature Logic: Non-blocking state machine for ALL roms
        if self._temp_roms and (time.ticks_ms() - self._last_temp_read > 1000):
            try:
                for rom in self._temp_roms:
                    rom_id = "".join("{:02x}".format(b) for b in rom)
                    self._last_temps[rom_id] = self._ds.read_temp(rom)

                self._ds.convert_temp()  # Trigger next conversion for all
                self._last_temp_read = time.ticks_ms()
            except Exception as e:
                print(f"Sensor error: {e}")
                if self.diagnostics:
                    self.diagnostics.increment("temp_read_errors")

        shock = 0
        if self._mpu:
            try:
                shock = self._mpu.get_shock_value()
            except Exception:
                if self.diagnostics:
                    self.diagnostics.increment("i2c_errors")

        # Primary temp is still first one or internal if none
        primary_temp = 0.0
        if self._last_temps:
            primary_temp = list(self._last_temps.values())[0]
        else:
            primary_temp = self.read_internal_c()

        # Update pre-allocated dictionary instead of creating a new one (Rule 3)
        self._read_result["lat"] = self._last_gps["lat"]
        self._read_result["lon"] = self._last_gps["lon"]
        self._read_result["speed"] = self._last_gps["speed"]
        self._read_result["gps_fix"] = self._last_gps["fix"]
        self._read_result["temp"] = primary_temp
        self._read_result["shock"] = shock
        self._read_result["battery_mv"] = self.read_battery_mv()
        self._read_result["internal_temp"] = self.read_internal_c()

        # Rule 5: Assertions for critical data sanity
        # Replaced assert with runtime check (B101 fix)
        if not (-180 <= self._read_result["lon"] <= 180):
            print(f"Warning: Lon out of bounds: {self._read_result['lon']}")
            self._read_result["lon"] = max(-180, min(180, self._read_result["lon"]))
            
        if not (-90 <= self._read_result["lat"] <= 90):
            print(f"Warning: Lat out of bounds: {self._read_result['lat']}")
            self._read_result["lat"] = max(-90, min(90, self._read_result["lat"]))

        return self._read_result

    def _read_gps(self):
        """Parse NMEA sentences from GPS - Non-blocking"""
        while self._gps_uart.any():
            try:
                line = self._gps_uart.readline()
                if line and b"$GPRMC" in line:
                    parts = line.decode().split(",")
                    if len(parts) >= 8 and parts[2] == "A":
                        self._last_gps["fix"] = True
                        self._last_gps["lat"] = self._parse_coord(parts[3], parts[4])
                        self._last_gps["lon"] = self._parse_coord(parts[5], parts[6])
                        try:
                            knots = float(parts[7])
                            self._last_gps["speed"] = knots * 1.852
                        except ValueError:
                            self._last_gps["speed"] = 0.0
                    else:
                        self._last_gps["fix"] = False
            except Exception as e:
                print(f"GPS parse error: {e}")
                if self.diagnostics:
                    self.diagnostics.increment("gps_parse_errors")

    def _parse_coord(self, value: str, direction: str) -> float:
        if not value or "." not in value:
            return 0.0
        try:
            dot_idx = value.find(".")
            degrees = float(value[: dot_idx - 2])
            minutes = float(value[dot_idx - 2 :])
            decimal = degrees + minutes / 60
            if direction in ("S", "W"):
                decimal = -decimal
            return decimal
        except ValueError:
            return 0.0
