import os
import machine
import time
from lib.logger import Logger

def compare_semver(remote, local):
    """
    Compare two semver strings.
    Returns:
        1 if remote > local
        -1 if remote < local
        0 if remote == local
    """
    try:
        r_parts = [int(p) for p in remote.split('.')]
        l_parts = [int(p) for p in local.split('.')]
        
        for i in range(max(len(r_parts), len(l_parts))):
            remote_val = r_parts[i] if i < len(r_parts) else 0
            local_val = l_parts[i] if i < len(l_parts) else 0
            if remote_val > local_val:
                return 1
            if remote_val < local_val:
                return -1
        return 0
    except Exception as e:
        Logger.log(f"OTA Utils: Semver parse error: {e}")
        return 0

def apply_firmware_update(config, temp_filename, target_filename, new_version=None):
    """
    Rename .tmp to actual file, backup old, bump version, and reset.
    """
    try:
        # Backup existing
        try:
            os.remove(f"{target_filename}.bak")
        except OSError:
            pass

        try:
            os.rename(target_filename, f"{target_filename}.bak")
        except OSError:
            pass

        # Rename temp to target
        os.rename(temp_filename, target_filename)
        Logger.log(f"OTA Utils: Applied {target_filename}")

        # Bump firmware version if provided, else auto-patch bump
        if config:
            if new_version:
                config.set("firmware_version", new_version)
                Logger.log(f"OTA Utils: Version set to {new_version}")
            else:
                try:
                    current = config.get("firmware_version") or "0.0.0"
                    parts = current.split(".")
                    parts[-1] = str(int(parts[-1]) + 1)
                    auto_version = ".".join(parts)
                    config.set("firmware_version", auto_version)
                    Logger.log(f"OTA Utils: Version auto-bumped to {auto_version}")
                except Exception as e:
                    Logger.log(f"OTA Utils: Version bump failed: {e}")

        Logger.log("OTA Utils: Resetting device in 2s...")
        time.sleep(2)
        machine.reset()

    except Exception as e:
        Logger.log(f"OTA Utils: Apply error: {e}")
        raise e
