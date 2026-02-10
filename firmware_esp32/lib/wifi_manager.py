import network
import time
import uasyncio as asyncio
from lib.logger import Logger

class WiFiManager:
    def __init__(self, config, status_led_callback=None):
        self.config = config
        self.wlan = network.WLAN(network.STA_IF)
        self.wlan.active(True)
        self._set_led = status_led_callback
        self._connecting = False

    async def connect(self):
        """Attempt to connect to WiFi using configured credentials"""
        ssid = self.config.get("wifi_ssid")
        password = self.config.get("wifi_pass")

        if not ssid:
            Logger.log("WiFi: No SSID configured.")
            return

        if self.wlan.isconnected():
            Logger.log(f"WiFi: Already connected to {ssid}")
            return

        Logger.log(f"WiFi: Connecting to {ssid}...")
        self._connecting = True
        self.wlan.connect(ssid, password)

        # Wait for connection with timeout
        for _ in range(20): # 20 attempts * 0.5s = 10s timeout
            if self.wlan.isconnected():
                Logger.log(f"WiFi: Connected! IP: {self.wlan.ifconfig()[0]}")
                self._connecting = False
                if self._set_led:
                    self._set_led((0, 10, 0)) # Green success flash
                    await asyncio.sleep_ms(500)
                    self._set_led((0, 0, 0))
                return
            
            if self._set_led:
                self._set_led((0, 0, 10)) # Blue working flash
            await asyncio.sleep_ms(250)
            if self._set_led:
                self._set_led((0, 0, 0))
            await asyncio.sleep_ms(250)

        Logger.log("WiFi: Connection failed.")
        self._connecting = False
        if self._set_led:
            self._set_led((10, 0, 0)) # Red failure flash
            await asyncio.sleep_ms(500)
            self._set_led((0, 0, 0))

    def is_connected(self):
        return self.wlan.isconnected()

    async def manage_connection(self):
        """Background task to keep WiFi alive"""
        while True:
            if not self.wlan.isconnected() and not self._connecting:
                 ssid = self.config.get("wifi_ssid")
                 if ssid: # Only try if we have config
                     await self.connect()
            
            await asyncio.sleep(60) # Check every minute
