# BLE GATT Server for ESP32-C6
import bluetooth
from micropython import const

_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)
_IRQ_GATTS_INDICATE_DONE = const(20)

class BLEAdvertiser:
    def __init__(self, name="Last-Mile-Tracker", service_uuid=None, version=1):
        self._ble = bluetooth.BLE()
        self._ble.active(True)
        self._ble.irq(self._irq)
        
        self._name = name
        self._version = version # Firmware version
        self._connected = False
        self._conn_handle = None
        self._write_callback = None
        
        # Register GATT service
        if service_uuid:
            self._register_services(service_uuid)
            
    def set_write_callback(self, callback):
        self._write_callback = callback
    
    def _register_services(self, service_uuid):
        """Register Environmental Sensing + OTA Service"""
        # Service and characteristic definitions
        ENV_SENSING_UUID = bluetooth.UUID(int(service_uuid, 16))
        
        # Sensor: Read + Notify (V1 - 24 bytes)
        SENSOR_CHAR = (
            bluetooth.UUID(0x2A6E),
            bluetooth.FLAG_READ | bluetooth.FLAG_NOTIFY,
        )
        
        # Extended Sensor: Read + Notify (V2 - Variable)
        EXTENDED_SENSOR_CHAR = (
            bluetooth.UUID(0x2A6F),
            bluetooth.FLAG_READ | bluetooth.FLAG_NOTIFY,
        )
        
        # OTA Control: Write + Notify
        OTA_CONTROL_CHAR = (
            bluetooth.UUID("00000001-0000-1000-8000-00805F9B34FB"),
            bluetooth.FLAG_WRITE | bluetooth.FLAG_NOTIFY,
        )
        
        # OTA Data: Write (No Response for speed)
        OTA_DATA_CHAR = (
            bluetooth.UUID("00000002-0000-1000-8000-00805F9B34FB"),
            bluetooth.FLAG_WRITE_NO_RESPONSE,
        )
        
        # WiFi Config: Write + Notify (for scan results)
        WIFI_CONFIG_CHAR = (
            bluetooth.UUID("0000FF01-0000-1000-8000-00805F9B34FB"),
            bluetooth.FLAG_WRITE | bluetooth.FLAG_NOTIFY,
        )
        
        ENV_SERVICE = (
            ENV_SENSING_UUID,
            (SENSOR_CHAR, EXTENDED_SENSOR_CHAR, OTA_CONTROL_CHAR, OTA_DATA_CHAR, WIFI_CONFIG_CHAR),
        )
        
        # handles: sensor, extended_sensor, ota_ctrl, ota_data, wifi_config
        ((self._sensor_handle, self._ext_sensor_handle, self._ota_ctrl_handle, self._ota_data_handle, self._wifi_config_handle),) = self._ble.gatts_register_services((ENV_SERVICE,))

    @property
    def ext_sensor_handle(self):
        return self._ext_sensor_handle

    @property
    def wifi_config_handle(self):
        return self._wifi_config_handle
    
    def _irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            self._conn_handle, _, _ = data
            self._connected = True
            print(f"Connected: {self._conn_handle}")
        
        elif event == _IRQ_CENTRAL_DISCONNECT:
            self._conn_handle = None
            self._connected = False
            print("Disconnected")
            # Restart advertising
            self.start_advertising()
            
        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            value = self._ble.gatts_read(value_handle)
            if self._write_callback:
                self._write_callback(conn_handle, value_handle, value)
    
    def restart_advertising(self, name=None):
        """Update advertising name and restart"""
        if name:
            self._name = name
        self._ble.gap_advertise(None) # Stop
        self.start_advertising()

    def start_advertising(self):
        """Start BLE advertising"""
        # Pre-allocate payload buffer (max 31 bytes for scan response/adv)
        self._payload_buf = bytearray(31)
        self._payload_len = 0
        self._update_payload(name=self._name) # Pass self._name
        # 100ms = 100,000us
        self._ble.gap_advertise(100_000, adv_data=self._advertising_payload())
        print(f"Advertising as '{self._name}'")
    
    def _update_payload(self, name=None, services=None, appearance=0):
        if not name:
            name = "LMT-Device"
            
        # Manually construct payload into bytearray to avoid intermediate 'bytes' objects (Rule 3)
        idx = 0
        # Flags
        self._payload_buf[idx:idx+3] = bytes([0x02, 0x01, 0x06])
        idx += 3
        
        # Complete local name
        name_bytes = name.encode()
        name_len = len(name_bytes)
        if idx + name_len + 2 <= 31:
            self._payload_buf[idx] = name_len + 1
            self._payload_buf[idx+1] = 0x09
            self._payload_buf[idx+2:idx+2+name_len] = name_bytes
            idx += name_len + 2
            
        if services:
            for uuid in services:
                b = bluetooth.UUID(uuid).bin
                if idx + len(b) + 2 <= 31:
                    self._payload_buf[idx] = len(b) + 1
                    self._payload_buf[idx+1] = 0x03 # Complete list of 16-bit Service UUIDs
                    self._payload_buf[idx+2:idx+2+len(b)] = b
                    idx += len(b) + 2
                    
        self._payload_len = idx

    def _advertising_payload(self, name=None, services=None, appearance=0):
        # Rule 3: Return a memoryview of the pre-allocated buffer
        return memoryview(self._payload_buf)[:self._payload_len]
    
    def is_connected(self) -> bool:
        return self._connected
    
    def notify(self, data: bytes, handle=None):
        """Send notification to connected central"""
        if self._connected and self._conn_handle is not None:
             # Default to sensor handle if none provided
            target_handle = handle if handle is not None else self._sensor_handle
            try:
                self._ble.gatts_notify(self._conn_handle, target_handle, data)
            except Exception as e:
                print(f"BLE Notify Error: {e}")
