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
from lib.st7789_display import Display
from lib.config import Config
from lib.diagnostics import Diagnostics
from lib.shock_buffer import ShockBuffer
from lib.ble_ota import BleOta
from lib.logger import Logger

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
        self.wdt.feed()
        
        self.device_id = self._init_device_id()
        
        try:
            self.np = neopixel.NeoPixel(Pin(NEOPIXEL_PIN), NUM_LEDS)
            self._set_led((0, 0, 0))
        except Exception:
            self.np = None
            
        try:
            self.display = Display()
        except Exception:
            self.display = None
        
        try:
            self.sensors = SensorHub(self.diagnostics)
        except Exception:
            self.sensors = None
        
        self.shock_buffer = ShockBuffer()
        self.ble = BLEAdvertiser(name=self.device_id, service_uuid=SERVICE_UUID)
        self.ota = BleOta()
        self.ble.set_write_callback(self.ota.handle_command)
        
        self._last_activity = time.time()
        self.data_store = {'lat':0.0, 'lon':0.0, 'speed':0.0, 'temp':0.0, 'shock':0, 'gps_fix':False}

    def _init_device_id(self):
        saved_id = self.config.get("device_id")
        if saved_id:
            return saved_id
        mac = ubinascii.hexlify(machine.unique_id()).decode()
        new_id = f"Last-Mile-{mac[-4:].upper()}"
        self.config.set("device_id", new_id)
        return new_id

    def _set_led(self, color):
        if self.np:
            self.np[0] = color
            self.np.write()

    def _pack_sensor_data(self, data):
        # Format: Lat(4), Lon(4), Speed(2), Temp(2), Shock(2), Bat(2), IntTemp(2), Trip(1), Reset(1), Uptime(4)
        # Total: 24 bytes
        return struct.pack('<ffHhHHHBBI', 
                           data['lat'], data['lon'], 
                           int(data['speed'] * 100), 
                           int(data['temp'] * 100), 
                           data['shock'],
                           data.get('battery_mv', 0),
                           int(data.get('internal_temp', 0) * 100),
                           0, # Trip state (0=Idle, 1=Moving) - logic to be added
                           machine.reset_cause(),
                           time.ticks_ms() // 1000)

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
                    if new_data['shock'] > 50 or new_data['speed'] > 1.0 or new_data['gps_fix']:
                        self._last_activity = time.time()
                    
                    # Shock handling
                    if new_data['shock'] > shock_threshold:
                        Logger.log(f"Shock Alert: {new_data['shock']}")
                        self.shock_buffer.add(new_data['shock'], time.ticks_ms())
                except Exception:
                    self.diagnostics.increment("sensor_read_fails")
            
            await asyncio.sleep_ms(100) # 10Hz sampling

    async def update_task(self):
        """UI and BLE update loop"""
        Logger.log("Task: UI/BLE update started.")
        update_interval = self.config.get("adv_interval") or 1000
        
        while True:
            # 1. LED status
            if self.ble.is_connected():
                self._set_led((0, 30, 0)) # Dim Green
            else:
                self._set_led((0, 0, 10)) # Dim Blue
                await asyncio.sleep_ms(20)
                self._set_led((0, 0, 0))

            # 2. Display
            if self.display:
                self.display.show_stats(
                    self.data_store['speed'], self.data_store['temp'], 
                    self.data_store['shock'], self.data_store['gps_fix']
                )

            # 3. BLE Notify
            if self.ble.is_connected():
                packed = self._pack_sensor_data(self.data_store)
                self.ble.notify(packed)
            
            await asyncio.sleep_ms(update_interval)

    async def maintenance_task(self):
        """Background flushes, GC and Sleep checks"""
        Logger.log("Task: Maintenance started.")
        sleep_timeout = self.config.get("sleep_timeout") or 300
        
        while True:
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

            await asyncio.sleep(5) # Every 5s

    async def main_loop(self):
        # Initialize WiFi
        from lib.wifi_manager import WiFiManager
        self.wifi = WiFiManager(self.config, self._set_led)
        
        # Handle BLE writes
        def handle_ble_write(conn_handle, value_handle, value):
            if value_handle == self.ble._wifi_config_handle:
                try:
                    # Format: "SSID:PASSWORD"
                    config_str = value.decode()
                    if ":" in config_str:
                        ssid, password = config_str.split(":", 1)
                        if ssid:
                            Logger.log(f"BLE: Received WiFi Config: {ssid}")
                            self.config.set("wifi_ssid", ssid)
                            self.config.set("wifi_pass", password)
                            # Trigger connection attempt (async)
                            asyncio.create_task(self.wifi.connect())
                except Exception as e:
                    Logger.log(f"BLE: WiFi Config Error: {e}")
            else:
                # Pass to OTA handler
                self.ota.handle_command(conn_handle, value_handle, value)

        self.ble.set_write_callback(handle_ble_write)
        self.ble.start_advertising()
        
        # Start tasks
        await asyncio.gather(
            self.sensor_task(),
            self.update_task(),
            self.maintenance_task(),
            self.wifi.manage_connection()
        )

if __name__ == "__main__":
    tracker = LastMileTracker()
    try:
        asyncio.run(tracker.main_loop())
    except Exception as e:
        Logger.log(f"CRITICAL: {e}")
        machine.reset()
