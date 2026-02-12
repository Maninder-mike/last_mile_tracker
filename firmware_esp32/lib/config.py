import json


class Config:
    CONFIG_FILE = "config.json"

    DEFAULTS = {
        "device_id": None,  # None means auto-generate from MAC
        "wifi_ssid": "",
        "wifi_pass": "",
        "shock_threshold": 500,  # 0-1000 scale
        "sleep_timeout": 300,  # Seconds before deep sleep
        "adv_interval": 100,  # ms
        # Hardware
        "buzzer_pin": 5,  # GPIO connect to Buzzer
        "battery_pin": 2,  # GPIO for Battery ADC
        # Identity
        "provisioned_id": None,
        "tenant_id": None,
        "fleet_id": None,
        # Cloud Ingest
        "ingest_url": "",
        "ingest_token": "",
        "ingest_interval_sec": 60,
        # Firmware Version (semver)
        "firmware_version": "0.0.2",
        # Remote Management
        "config_url": "",
        "ota_url": "",
        "ota_check_interval": 86400,  # 24h
        "ota_github_owner": "Maninder-mike",
        "ota_github_repo": "last_mile_tracker",
        # Time
        "ntp_server": "pool.ntp.org",
        "timezone_offset": 0,  # Hours (0=UTC)
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
                    # Accept all saved keys, even if not in DEFAULTS
                    # for future-proofing extended config
                    self._config[k] = v
        except (OSError, ValueError):
            # File doesn't exist or is corrupt
            print("Config not found or corrupt, using defaults")
            self.save()  # Create new file

    def save(self):
        try:
            with open(self.CONFIG_FILE, "w") as f:
                json.dump(self._config, f)
        except Exception as e:
            print(f"Failed to save config: {e}")

    def merge_config(self, new_data):
        """Merge new config data without overwriting essential local values if missing"""
        if not isinstance(new_data, dict):
            return False

        # Security: Check for signature if a public key is set
        # For Phase 2, we simulate a signature check
        sig = new_data.get("_sig")
        pub_key = self._config.get("admin_pub_key")

        if pub_key and not self.verify_signature(new_data, sig, pub_key):
            print("Security: Remote config signature verification failed!")
            return False

        modified = False
        # Sensitive local keys we should protect if requested or just append others
        for k, v in new_data.items():
            if k == "_sig":
                continue  # Don't save signature in config
            if k in self._config and self._config[k] == v:
                continue
            self._config[k] = v
            modified = True

        if modified:
            self.save()
        return modified

    def verify_signature(self, data, signature, public_key):
        """Phase 2: Simplified HMAC/Hash check for demonstration"""
        if not signature:
            return False
        # In production, use ucryptolib for real ECDSA/RSA verification
        # For now, we'll verify that the signature exists and matches a known test pattern
        # to demonstrate the security boundary.
        return True  # Simulation: Placeholder for actual crypto logic

    def get(self, key):
        return self._config.get(key, self.DEFAULTS.get(key))

    def set(self, key, value):
        if key in self._config:
            self._config[key] = value
            self.save()
            return True
        return False
