import gc
import hashlib
import urequests
from lib.logger import Logger
from lib.ota_utils import compare_semver, apply_firmware_update

class WiFiOta:
    def __init__(self, config):
        self.config = config
        self.owner = config.get("ota_github_owner")
        self.repo = config.get("ota_github_repo")
        self.current_version = config.get("firmware_version") or "0.0.0"

    def check_and_update(self):
        """Check GitHub for new firmware and update if found."""
        Logger.log("WiFi OTA: Checking for updates...")
        
        try:
            url = f"https://api.github.com/repos/{self.owner}/{self.repo}/releases/latest"
            # GitHub API requires a User-Agent
            headers = {"User-Agent": "ESP32-LastMileTracker", "Accept": "application/vnd.github.v3+json"}
            
            res = urequests.get(url, headers=headers)
            if res.status_code != 200:
                Logger.log(f"WiFi OTA: API error {res.status_code}")
                res.close()
                return

            data = res.json()
            res.close()
            
            tag_name = data.get("tag_name", "v0.0.0")
            # Parse version from fw-v0.0.1 or v0.0.1
            remote_version = tag_name.replace("fw-", "").replace("v", "")
            
            if compare_semver(remote_version, self.current_version) > 0:
                Logger.log(f"WiFi OTA: New version available: {remote_version} (Current: {self.current_version})")
                self._perform_update(data, remote_version)
            else:
                Logger.log(f"WiFi OTA: Up to date ({self.current_version})")

        except Exception as e:
            Logger.log(f"WiFi OTA: Check failed: {e}")

    def _perform_update(self, release_data, new_version):
        """Download and apply the update."""
        assets = release_data.get("assets", [])
        
        firmware_asset = None
        sha_asset = None
        
        for asset in assets:
            name = asset["name"]
            if name == "main.py":
                firmware_asset = asset
            elif name == "main.py.sha256":
                sha_asset = asset

        if not firmware_asset:
            Logger.log("WiFi OTA: No firmware asset (main.py) found in release.")
            return

        expected_hash = None
        if sha_asset:
            try:
                Logger.log("WiFi OTA: Fetching SHA-256 checksum...")
                res = urequests.get(sha_asset["browser_download_url"])
                if res.status_code == 200:
                    # Expected content: "hash  filename\n" or just "hash"
                    content = res.text.strip()
                    expected_hash = content.split()[0]
                    Logger.log(f"WiFi OTA: Expected hash: {expected_hash}")
                res.close()
            except Exception as e:
                Logger.log(f"WiFi OTA: Failed to fetch checksum: {e}")

        # Download firmware
        try:
            temp_file = "ota_update.py.tmp"
            Logger.log(f"WiFi OTA: Downloading {firmware_asset['name']} ({firmware_asset['size']} bytes)...")
            
            download_url = firmware_asset["browser_download_url"]
            
            # Using chunked download to save memory
            res = urequests.get(download_url, stream=True)
            if res.status_code != 200:
                Logger.log(f"WiFi OTA: Download failed with status {res.status_code}")
                res.close()
                return

            sha256 = hashlib.sha256()
            with open(temp_file, "wb") as f:
                while True:
                    chunk = res.raw.read(1024 * 4) # 4KB chunks
                    if not chunk:
                        break
                    f.write(chunk)
                    sha256.update(chunk)
                    # Manually trigger GC to keep memory free
                    gc.collect()
            
            res.close()
            
            actual_hash_hex = "".join(["%02x" % b for b in sha256.digest()])
            
            if expected_hash and actual_hash_hex != expected_hash.lower():
                Logger.log(f"WiFi OTA: Hash mismatch! Got {actual_hash_hex}, expected {expected_hash}")
                import os
                try:
                    os.remove(temp_file)
                except Exception:
                    pass
                return
            
            Logger.log("WiFi OTA: Download verified. Applying update...")
            apply_firmware_update(self.config, temp_file, "main.py", new_version)
            
        except Exception as e:
            Logger.log(f"WiFi OTA: Update failed: {e}")
            import os
            try:
                os.remove(temp_file)
            except Exception:
                pass
