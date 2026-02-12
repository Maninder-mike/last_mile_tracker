# main.py - Last-Mile-Tracker ESP32-C6 Firmware (Performance Optimized)
import time
import struct
import neopixel
import machine
import ubinascii
import uasyncio as asyncio
from machine import Pin, WDT
from lib.ble_advertising import BLEAdvertiser
from lib.sensors import SensorHub

# from lib.st7789_display import Display
from lib.config import Config
from lib.diagnostics import Diagnostics
from lib.shock_buffer import ShockBuffer
from lib.ble_ota import BleOta
from lib.logger import Logger
from lib.sd_logger import SDLogger
from lib.buzzer import Buzzer
from lib.http_poster import HttpPoster
from lib.ntp_time import NTPClient

# Constants
NEOPIXEL_PIN = 8
NUM_LEDS = 1
SERVICE_UUID = "181A"


class LastMileTracker:
    def __init__(self):
        Logger.log("Booting Last-Mile Optimized Firmware...")

        self.config = Config()
        self.diagnostics = Diagnostics(self.config)
        self.wdt = WDT(timeout=30000)

        # Rule 2: Multi-task health monitoring for Rule 2 (Bounded Loops)
        self._task_ticks = {
            "sensor": time.ticks_ms(),
            "update": time.ticks_ms(),
            "cloud": time.ticks_ms(),
        }

        # Rule 5: Critical startup invariant assertions
        assert self.config.get("shock_threshold") >= 0, "Invalid shock threshold"
        assert self.config.get("ingest_interval") >= 1, "Ingest interval too low"

        # Rule 3: Pre-allocate BLE data buffers to avoid heap churn
        self._v1_buf = bytearray(24)
        self._v2_buf = bytearray(76)
        self._v2_length = 0

        # Shared sensor state
        self._reading = {}
        self.wdt.feed()

        self.device_id = self._init_device_id()

        try:
            self.np = neopixel.NeoPixel(Pin(NEOPIXEL_PIN), NUM_LEDS)
            self._set_led((0, 0, 0))
        except Exception:
            self.np = None

        # Display - Disabled for Prototype
        self.display = None
        # try:
        #     self.display = Display()
        # except Exception:
        #     self.display = None

        try:
            self.sensors = SensorHub(self.diagnostics)
        except Exception:
            self.sensors = None

        self.sd_logger = SDLogger()
        self.http_poster = HttpPoster(self.config, self.diagnostics)
        self.shock_buffer = ShockBuffer()

        # Buzzer Init
        buzzer_pin = self.config.get("buzzer_pin")
        self.buzzer = Buzzer(buzzer_pin)
        self.buzzer.beep(100)  # Boot beep

        self.ble = BLEAdvertiser(name=self.device_id, service_uuid=SERVICE_UUID)
        self.ota = BleOta(config=self.config)
        self.ble.set_write_callback(self.handle_ble_write)

        # Report firmware version via BLE
        fw_version = self.config.get("firmware_version") or "0.0.1"
        self.ble.set_firmware_version(fw_version)
        Logger.log(f"Firmware Version: {fw_version}")

        self._last_activity = time.time()
        self.data_store = {
            "lat": 0.0,
            "lon": 0.0,
            "speed": 0.0,
            "temp": 0.0,
            "shock": 0,
            "gps_fix": False,
        }

    def _init_device_id(self):
        # 1. Check for provisioned ID first (for fleet scale)
        p_id = self.config.get("provisioned_id")
        if p_id:
            Logger.log(f"Identity: Using Provisioned ID: {p_id}")
            return p_id

        # 2. Check for saved manual ID
        saved_id = self.config.get("device_id")
        if saved_id:
            return saved_id

        # 3. Fallback to MAC-based ID
        mac = ubinascii.hexlify(machine.unique_id()).decode()
        new_id = f"Last-Mile-{mac[-4:].upper()}"
        self.config.set("device_id", new_id)
        return new_id

    def _set_led(self, color):
        if self.np:
            self.np[0] = color
            self.np.write()

    def _pack_sensor_data(self, data):
        """Rule 3: Use pre-allocated buffer for V1 packet"""
        struct.pack_into(
            "<ffffHHHBBH",
            self._v1_buf,
            0,
            data["lat"],
            data["lon"],
            data["speed"],
            data["temp"],
            data["shock"],
            data["battery_mv"],
            int(data["internal_temp"]),
            1 if data["gps_fix"] else 0,
            0,  # Reset reason placeholder
            int(time.time() % 65535),
        )
        return self._v1_buf

    def _pack_extended_data(self, data):
        """Rule 3: Build V2 packet into pre-allocated buffer"""
        all_temps = data.get("all_temps", {})
        num_temps = min(len(all_temps), 10)

        # Version 2 header (Rule 3: Writing directly to pre-allocated bytearray)
        self._v2_buf[0] = 2
        self._v2_buf[1] = num_temps

        offset = 2
        for i, (rom_id, val) in enumerate(all_temps.items()):
            if i >= num_temps:
                break
            struct.pack_into("<h", self._v2_buf, offset, int(val * 100))
            offset += 2

        # Battery Drop (scaled x1000)
        struct.pack_into("<h", self._v2_buf, offset, int(data.get("bat_drop", 0) * 1000))
        offset += 2

        self._v2_length = offset
        return memoryview(self._v2_buf)[: self._v2_length]

    async def sensor_task(self):
        """High-frequency sensor monitoring"""
        Logger.log("Task: Sensor monitor started.")
        shock_threshold = self.config.get("shock_threshold") or 500

        while True:
            if self.sensors:
                try:
                    new_data = await self.sensors.read_all()
                    self.data_store.update(new_data)

                    # Activity check
                    if new_data["shock"] > 50 or new_data["speed"] > 1.0 or new_data["gps_fix"]:
                        self._last_activity = time.time()

                    # Shock handling
                    if new_data["shock"] > shock_threshold:
                        Logger.log(f"Shock Alert: {new_data['shock']}")
                        self.shock_buffer.add(new_data["shock"], time.ticks_ms())
                        asyncio.create_task(self.buzzer.alarm())

                    # SD Logging (Local backup)
                    # For now, log if we have a fix or every 10 samples to save SD life
                    if new_data["gps_fix"] or (int(time.time()) % 10 == 0):
                        self.sd_logger.log(new_data)

                except Exception:
                    self.diagnostics.increment("sensor_read_fails")

            # Rule 2: Mark task as healthy
            self._task_ticks["sensor"] = time.ticks_ms()
            await asyncio.sleep_ms(100)  # 10Hz sampling

    async def update_task(self):
        """UI and BLE update loop"""
        Logger.log("Task: UI/BLE update started.")
        update_interval = self.config.get("adv_interval") or 1000

        while True:
            # 1. LED status
            if self.ble.is_connected():
                self._set_led((0, 30, 0))  # Dim Green
            else:
                self._set_led((0, 0, 10))  # Dim Blue
                await asyncio.sleep_ms(20)
                self._set_led((0, 0, 0))

            # 2. Display
            if self.display:
                self.display.show_stats(
                    self.data_store["speed"],
                    self.data_store["temp"],
                    self.data_store["shock"],
                    self.data_store["gps_fix"],
                )

            # 3. BLE Notify
            if self.ble.is_connected():
                # V1 Legacy Data
                packed_v1 = self._pack_sensor_data(self.data_store)
                self.ble.notify(packed_v1)

                # V2 Extended Data (Optional delay to avoid congestion)
                await asyncio.sleep_ms(50)
                packed_ext = self._pack_extended_data(self.data_store)
                self.ble.notify(packed_ext, self.ble.ext_sensor_handle)

            # Rule 2: Mark task as healthy
            self._task_ticks["update"] = time.ticks_ms()
            await asyncio.sleep_ms(update_interval)

    async def maintenance_task(self):
        """Background flushes, GC and Sleep checks"""
        Logger.log("Task: Maintenance started.")
        sleep_timeout = self.config.get("sleep_timeout") or 300

        while True:
            # Rule 2: Check health of all tasks before feeding hardware watchdog
            now = time.ticks_ms()
            all_healthy = True
            for task, last_tick in self._task_ticks.items():
                if time.ticks_diff(now, last_tick) > 60000:  # 1 minute grace
                    Logger.log(f"CRITICAL: Task {task} hung!")
                    all_healthy = False

            if all_healthy:
                self.wdt.feed()

            # Flush buffers
            Logger.flush()
            self.diagnostics.flush()

            # GC
            import gc

            gc.collect()

            # Deep Sleep check
            if (time.time() - self._last_activity) > sleep_timeout:
                Logger.log("Entering Deep Sleep...")
                Logger.flush()
                self.diagnostics.flush()
                if self.display:
                    self.display.clear()
                    self.display.backlight(False)
                self._set_led((0, 0, 0))
                machine.deepsleep(3600 * 1000)

            await asyncio.sleep(5)  # Every 5s

    def handle_ble_write(self, conn_handle, value_handle, value):
        """Callback for when a central writes to a characteristic"""
        if value_handle == self.ble.wifi_config_handle:
            try:
                command = value.decode().strip()
                Logger.log(f"BLE: WiFi Config Write: {command}")

                if command == "CMD:SCAN":
                    Logger.log("BLE: Received Scan Command - Starting WiFi Scan")

                    async def perform_scan():
                        try:
                            networks = await self.wifi.scan_networks()
                            Logger.log(
                                f"BLE: Scan found {len(networks)} networks. Sending notifications..."
                            )
                            for ssid, rssi in networks:
                                # Send "SSID,RSSI" notification
                                payload = f"{ssid},{rssi}".encode()
                                self.ble.notify(payload, self.ble.wifi_config_handle)
                                await asyncio.sleep_ms(150)  # Stable delay

                            # Signal end of scan
                            Logger.log("BLE: Scan notified ALL - Sending SCAN:END")
                            self.ble.notify(b"SCAN:END", self.ble.wifi_config_handle)
                        except Exception as e:
                            Logger.log(f"BLE: Scan task error: {e}")

                    asyncio.create_task(perform_scan())
                    return

                if command == "CMD:IDENTIFY":
                    Logger.log("BLE: Received Identify Command")

                    async def identify():
                        for _ in range(10):
                            self._set_led((10, 10, 10))  # White
                            await asyncio.sleep_ms(100)
                            self._set_led((0, 0, 0))
                            await asyncio.sleep_ms(100)

                    asyncio.create_task(identify())
                    return

                if command == "CMD:REBOOT":
                    Logger.log("BLE: Received Reboot Command")

                    async def reboot():
                        await asyncio.sleep(1)
                        machine.reset()

                    asyncio.create_task(reboot())
                    return

                if command == "CMD:RESET_WIFI":
                    Logger.log("BLE: Received Reset WiFi Command")
                    self.config.set("wifi_ssid", "")
                    self.config.set("wifi_pass", "")

                    async def reset_wifi():
                        await self.wifi.disconnect()
                        Logger.log("WiFi: Config cleared and disconnected.")

                    asyncio.create_task(reset_wifi())
                    return

                # Format: "SSID:PASSWORD"
                if ":" in command:
                    parts = command.split(":", 1)
                    if len(parts) == 2:
                        ssid, password = parts
                        if ssid:
                            Logger.log(f"BLE: Received WiFi Config: {ssid}")
                            self.config.set("wifi_ssid", ssid)
                            self.config.set("wifi_pass", password)

                            def on_wifi_status(status, detail):
                                # Send "WIFI:CONNECTED:SSID" or "WIFI:FAILED:Reason"
                                payload = f"WIFI:{status}:{detail}".encode()
                                self.ble.notify(payload, self.ble.wifi_config_handle)
                                Logger.log(f"BLE: Notified WiFi Status: {status} ({detail})")

                            # Trigger connection attempt (async)
                            asyncio.create_task(self.wifi.connect(on_status_change=on_wifi_status))
            except Exception as e:
                Logger.log(f"BLE: WiFi Config Error: {e}")
        elif value_handle in (self.ble.ota_ctrl_handle, self.ble.ota_data_handle):
            # Route OTA writes explicitly
            self.ota.handle_command(value)

    async def cloud_upload_task(self):
        """Periodic telemetry upload to cloud via WiFi with Adaptive Sampling"""
        Logger.log("Task: Cloud ingest started.")
        retry_buffer = []  # Simple in-memory retry buffer

        while True:
            # Adaptive Sampling Logic
            # Default to config or standard intervals
            ingest_int = self.config.get("ingest_interval_sec") or 60
            idle_int = self.config.get("ingest_interval_idle") or 900  # 15 min default idle

            # Use data_store trip_state (1 if moving, 0 if idle)
            trip_state = self.data_store.get("trip_state", 0)

            # If idle for too long, switch to idle_int
            current_time = time.time()
            if trip_state == 0 and (current_time - self._last_activity > 300):
                interval = idle_int
            else:
                interval = ingest_int

            url = self.config.get("ingest_url")

            if url and self.wifi.is_connected():
                # Measure battery before upload for profiling
                v_before = self.sensors.read_battery_mv() if self.sensors else 0

                # 1. Try to post current data
                success = await self.http_poster.post_telemetry(self.data_store)

                # Measure battery after upload
                v_after = self.sensors.read_battery_mv() if self.sensors else 0
                if success and v_before > 0:
                    drop = v_before - v_after
                    self.data_store["bat_drop"] = drop  # Store for next reporting cycle

                # 2. If success, try to flush retry buffer
                if success and retry_buffer:
                    Logger.log(f"WiFi: Flushing {len(retry_buffer)} buffered readings")
                    while retry_buffer:
                        buffered = retry_buffer.pop(0)
                        if not await self.http_poster.post_telemetry(buffered):
                            retry_buffer.insert(0, buffered)  # Partial failure
                            break
                elif not success:
                    # Buffer current data on failure
                    if len(retry_buffer) < 50:  # Limit buffer size
                        retry_buffer.append(self.data_store.copy())

            # Rule 2: Mark task as healthy
            self._task_ticks["cloud"] = time.ticks_ms()
            await asyncio.sleep(interval)

    async def remote_management_task(self):
        """Check for remote config and OTA updates monthly/daily"""
        Logger.log("Task: Remote management started.")
        import urequests

        while True:
            # 1. Remote Config
            config_url = self.config.get("config_url")
            if config_url and self.wifi.is_connected():
                try:
                    Logger.log("WiFi: Fetching remote config...")
                    res = urequests.get(config_url)
                    if res.status_code == 200:
                        new_cfg = res.json()
                        if self.config.merge_config(new_cfg):
                            Logger.log("WiFi: Remote config applied.")
                    res.close()
                except Exception as e:
                    Logger.log(f"WiFi: Remote config check failed: {e}")

            # 2. WiFi OTA (Simplified check)
            ota_url = self.config.get("ota_url")
            if ota_url and self.wifi.is_connected():
                # Future implementation: compare version from metadata
                pass

            await asyncio.sleep(3600 * 24)  # Check daily

    async def main_loop(self):
        # Initialize NTP
        self.ntp = NTPClient(self.config)

        # Initialize WiFi
        from lib.wifi_manager import WiFiManager

        self.wifi = WiFiManager(self.config, self._set_led, ntp_client=self.ntp)

        # Handle BLE writes
        self.ble.set_write_callback(self.handle_ble_write)
        self.ble.start_advertising()

        # Start tasks
        await asyncio.gather(
            self.sensor_task(),
            self.update_task(),
            self.maintenance_task(),
            self.wifi.manage_connection(),
            self.cloud_upload_task(),
            self.remote_management_task(),
        )


if __name__ == "__main__":
    tracker = LastMileTracker()
    try:
        asyncio.run(tracker.main_loop())
    except Exception as e:
        import time

        print(f"CRITICAL ERROR: {e}")  # Print to REPL
        Logger.log(f"CRITICAL: {e}")
        time.sleep(5)  # Give time to read/flush
        machine.reset()
