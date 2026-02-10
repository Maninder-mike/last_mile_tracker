


class Diagnostics:
    SAVE_THRESHOLD = 5 # Save every 5 increments
    
    def __init__(self, config):
        self.config = config
        self.counters = {
            "reboots": 0,
            "i2c_errors": 0,
            "ble_disconnects": 0,
            "gps_lost": 0,
            "watchdog_resets": 0,
            "sensor_read_fails": 0,
            "http_post_ok": 0,
            "http_post_fail": 0,
            "sd_write_fail": 0,
            "exceptions": 0
        }
        self._unsaved_count = 0
        self._load()
        
        # Increment reboot counter on startup
        self.increment("reboots")
        
    def _load(self):
        saved = self.config.get("diagnostics")
        if saved:
            for k, v in saved.items():
                self.counters[k] = v
                
    def flush(self):
        """Manually flush diagnostics to storage"""
        if self._unsaved_count > 0:
            self.config.set("diagnostics", self.counters)
            self._unsaved_count = 0
            print("Diagnostics: Flushed to config.")

    def increment(self, metric):
        if metric not in self.counters:
            self.counters[metric] = 0
            
        self.counters[metric] += 1
        self._unsaved_count += 1
        
        print(f"Diagnostics: {metric} -> {self.counters[metric]}")
        
        if self._unsaved_count >= self.SAVE_THRESHOLD:
            self.flush()
            
    def get_report(self):
        return self.counters
