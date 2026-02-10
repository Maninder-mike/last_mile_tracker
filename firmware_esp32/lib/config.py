import json

class Config:
    CONFIG_FILE = "config.json"
    
    DEFAULTS = {
        "device_id": None,      # None means auto-generate from MAC
        "wifi_ssid": "",
        "wifi_pass": "",
        "shock_threshold": 500, # 0-1000 scale
        "sleep_timeout": 300,   # Seconds before deep sleep
        "adv_interval": 100,    # ms
    }
    
    def __init__(self):
        self._config = self.DEFAULTS.copy()
        self.load()
        
    def load(self):
        try:
            with open(self.CONFIG_FILE, "r") as f:
                saved = json.load(f)
                # Update defaults with saved values
                for k, v in saved.items():
                    if k in self._config:
                        self._config[k] = v
        except (OSError, ValueError):
            # File doesn't exist or is corrupt
            print("Config not found or corrupt, using defaults")
            self.save() # Create new file
            
    def save(self):
        try:
            with open(self.CONFIG_FILE, "w") as f:
                json.dump(self._config, f)
        except Exception as e:
            print(f"Failed to save config: {e}")
            
    def get(self, key):
        return self._config.get(key, self.DEFAULTS.get(key))
        
    def set(self, key, value):
        if key in self._config:
            self._config[key] = value
            self.save()
            return True
        return False
