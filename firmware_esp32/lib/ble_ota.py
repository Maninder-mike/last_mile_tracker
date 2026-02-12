import os
import hashlib
from lib.logger import Logger


class BleOta:
    # Commands
    CMD_START = 0x01
    CMD_DATA = 0x02
    CMD_END = 0x03

    def __init__(self, config=None):
        self._config = config
        self._update_filename = None
        self._file_handle = None
        self._received_size = 0
        self._expected_size = 0
        self._hash = None

    def handle_command(self, cmd_bytes):
        """Handle incoming OTA commands from BLE"""
        if not cmd_bytes:
            return

        cmd = cmd_bytes[0]
        data = cmd_bytes[1:]

        if cmd == self.CMD_START:
            self._handle_start(data)
        elif cmd == self.CMD_DATA:
            self._handle_data(data)
        elif cmd == self.CMD_END:
            self._handle_end(data)

    def _handle_start(self, data):
        """Start update: [type(1), size(4)]"""
        try:
            import struct
            # file_type = data[0] # 1=main.py, 2=lib... for now logic is simpler
            # We'll expect a filename length and filename next, or just hardcode for main.py for v1
            # Let's assume protocol: [size(4), name_len(1), name(...)]

            size = struct.unpack("<I", data[0:4])[0]
            name_len = data[4]
            name = data[5 : 5 + name_len].decode()

            self._expected_size = size
            self._update_filename = f"{name}.tmp"
            self._received_size = 0
            self._hash = hashlib.sha256()

            self._file_handle = open(self._update_filename, "wb")
            Logger.log(f"OTA: Starting upload for {name} ({size} bytes)")

        except Exception as e:
            Logger.log(f"OTA Start Error: {e}")
            self._close_file()

    def _handle_data(self, data):
        """Append data chunk"""
        if not self._file_handle:
            return

        try:
            self._file_handle.write(data)
            self._hash.update(data)
            self._received_size += len(data)

            # Optional: Log every k byte
            if self._received_size % 2048 == 0:
                print(f"OTA: {self._received_size}/{self._expected_size}")

        except Exception as e:
            Logger.log(f"OTA Write Error: {e}")
            self._close_file()

    def _handle_end(self, data):
        """Finish: [checksum(32)]"""
        if not self._file_handle:
            return
        self._close_file()

        try:
            expected_hash = data  # Assuming raw bytes
            actual_hash = self._hash.digest()

            if expected_hash == actual_hash:
                Logger.log("OTA: Checksum OK. Applying update...")
                self._apply_update()
            else:
                Logger.log("OTA: Checksum MISMATCH!")
                try:
                    os.remove(self._update_filename)
                except OSError:
                    pass

        except Exception as e:
            Logger.log(f"OTA End Error: {e}")

    def _close_file(self):
        if self._file_handle:
            self._file_handle.close()
            self._file_handle = None

    def _apply_update(self):
        """Rename .tmp to actual file and reset"""
        try:
            from lib.ota_utils import apply_firmware_update

            target = self._update_filename.replace(".tmp", "")
            apply_firmware_update(
                config=self._config, temp_filename=self._update_filename, target_filename=target
            )
        except Exception as e:
            Logger.log(f"OTA Apply Error: {e}")
