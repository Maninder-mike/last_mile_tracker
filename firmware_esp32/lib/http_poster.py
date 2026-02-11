# http_poster.py - Lightweight cloud ingest client
import urequests
import time


class HttpPoster:
    def __init__(self, config, diagnostics=None):
        self.config = config
        self.diagnostics = diagnostics
        self._last_sent_data = None
        self._last_sent_time = 0

    def _should_send(self, data):
        """Check if data has changed enough to warrant an upload (Bandwidth Optimization)"""
        if self._last_sent_data is None:
            return True

        now = time.time()
        # Force a heartbeat every 1 hour regardless of change
        if now - self._last_sent_time > 3600:
            return True

        # 1. Check movement (Lat/Lon) - threshold ~10m
        d_lat = abs(data["lat"] - self._last_sent_data["lat"])
        d_lon = abs(data["lon"] - self._last_sent_data["lon"])
        if d_lat > 0.0001 or d_lon > 0.0001:
            return True

        # 2. Check major sensors (Primary)
        d_temp = abs(data.get("temp", 0) - self._last_sent_data.get("temp", 0))
        if d_temp > 0.5:
            return True

        # 2b. Check all other temps (V2)
        current_temps = data.get("all_temps", {})
        last_temps = self._last_sent_data.get("all_temps", {})
        for rom, val in current_temps.items():
            if abs(val - last_temps.get(rom, -999)) > 0.5:
                return True

        if data.get("shock", 0) > self.config.get("shock_threshold"):
            return True

        # No significant change
        return False

    async def post_telemetry(self, data):
        if not self._should_send(data):
            # Quietly skip to save bandwidth
            return True  # Pretend success as no action was needed

        url = self.config.get("ingest_url")
        token = self.config.get("ingest_token")

        if not url:
            return False

        # Timestamp validity check
        ts = time.time()
        is_synced = ts > 1704067200  # Jan 1 2024

        payload = {
            "device_id": self.config.get("device_id"),
            "provisioned_id": self.config.get("provisioned_id"),
            "tenant_id": self.config.get("tenant_id"),
            "timestamp": ts,
            "ts_synced": is_synced,
            "data": data,
        }

        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"

        try:
            # Simple urequests POST
            response = urequests.post(url, json=payload, headers=headers)
            status = response.status_code
            response.close()

            if 200 <= status < 300:
                if self.diagnostics:
                    self.diagnostics.increment("http_post_ok")
                self._last_sent_data = data.copy()
                self._last_sent_time = time.time()
                return True
            else:
                if self.diagnostics:
                    self.diagnostics.increment("http_post_fail")
                return False
        except Exception as e:
            print(f"HTTP Post Error: {e}")
            if self.diagnostics:
                self.diagnostics.increment("http_post_fail")
            return False
