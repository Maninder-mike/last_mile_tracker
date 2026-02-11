import network

import uasyncio as asyncio
from lib.logger import Logger

class WiFiManager:
    def __init__(self, config, status_led_callback=None, ntp_client=None):
        self.config = config
        self.wlan = network.WLAN(network.STA_IF)
        self.wlan.active(True)
        self._set_led = status_led_callback
        self.ntp_client = ntp_client
        self._connecting = False

    async def connect(self, on_status_change=None):
        """Attempt to connect to WiFi using configured credentials"""
        if self._connecting:
            Logger.log("WiFi: Connection already in progress. Skipping.")
            return False

        ssid = self.config.get("wifi_ssid")
        password = self.config.get("wifi_pass")

        if not ssid:
            Logger.log("WiFi: No SSID configured.")
            if on_status_change:
                on_status_change("FAILED", "No SSID")
            return False

        if self.wlan.isconnected():
            Logger.log(f"WiFi: Already connected to {ssid}")
            if on_status_change:
                on_status_change("CONNECTED", ssid)
            # Ensure time is synced even if already connected
            if self.ntp_client and not self.ntp_client.is_synced():
                self.ntp_client.sync()
            return True

        Logger.log(f"WiFi: Connecting to {ssid}...")
        self._connecting = True
        try:
            if not self.wlan.active():
                self.wlan.active(True)
            self.wlan.connect(ssid, password)
        except Exception as e:
            Logger.log(f"WiFi: Immediate connect error: {e}")
            self._connecting = False
            return False

        # Status mapping for MicroPython network.WLAN
        # 1000: STAT_IDLE
        # 1001: STAT_CONNECTING
        # 1010: STAT_GOT_IP
        # 201:  STAT_NO_AP_FOUND
        # 202:  STAT_WRONG_PASSWORD
        # 203:  STAT_BEACON_TIMEOUT
        # 204:  STAT_ASSOC_FAIL

        # Wait for connection with timeout
        for i in range(30): # 30 attempts * 0.5s = 15s timeout
            status = self.wlan.status()
            if self.wlan.isconnected():
                Logger.log(f"WiFi: Connected! IP: {self.wlan.ifconfig()[0]}")
                self._connecting = False
                if self._set_led:
                    self._set_led((0, 10, 0)) # Green success flash
                
                # Sync Time
                if self.ntp_client:
                    self.ntp_client.sync()

                if on_status_change:
                    on_status_change("CONNECTED", ssid)
                return True
            
            if status == 202: # STAT_WRONG_PASSWORD
                Logger.log("WiFi: Error - Wrong Password")
                break
            elif status == 201: # STAT_NO_AP_FOUND
                Logger.log("WiFi: Error - AP Not Found")
                break
            
            if i % 4 == 0:
                Logger.log(f"WiFi: Status={status}...")

            if self._set_led:
                self._set_led((0, 0, 10)) # Blue working flash
            await asyncio.sleep_ms(250)
            if self._set_led:
                self._set_led((0, 0, 0))
            await asyncio.sleep_ms(250)

        Logger.log(f"WiFi: Connection failed. Status: {self.wlan.status()}")
        self._connecting = False
        if self._set_led:
            self._set_led((10, 0, 0)) # Red failure flash
            await asyncio.sleep_ms(500)
            self._set_led((0, 0, 0))
        
        if on_status_change:
            err = "Timeout"
            if self.wlan.status() == 202:
                err = "Wrong Password"
            elif self.wlan.status() == 201:
                err = "AP Not Found"
            on_status_change("FAILED", err)
            
        return False

    async def disconnect(self):
        """Disconnect from WiFi and de-activate interface"""
        Logger.log("WiFi: Disconnecting...")
        self.wlan.disconnect()
        self.wlan.active(False)
        self._connecting = False
        return True

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

    async def scan_networks(self):
        """Scan for available WiFi networks"""
        Logger.log("WiFi: Scanning networks...")
        self.wlan.active(True)
        try:
            # scan() returns list of tuples: (ssid, bssid, channel, RSSI, authmode, hidden)
            networks = self.wlan.scan()
            
            # Filter empty SSIDs and sort by RSSI (signal strength)
            # Tuple index 0 is SSID, 3 is RSSI
            valid_networks = [n for n in networks if n[0]]
            valid_networks.sort(key=lambda x: x[3], reverse=True)
            
            unique_ssids = []
            seen = set()
            for n in valid_networks:
                ssid = n[0].decode('utf-8')
                if ssid not in seen:
                    unique_ssids.append((ssid, n[3]))
                    seen.add(ssid)
            
            Logger.log(f"WiFi: Found {len(unique_ssids)} networks")
            return unique_ssids
        except Exception as e:
            Logger.log(f"WiFi: Scan error: {e}")
            return []
