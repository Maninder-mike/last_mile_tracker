# BLE GATT Server for ESP32-C6
import bluetooth
from micropython import const

_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_INDICATE_DONE = const(20)

class BLEAdvertiser:
    def __init__(self, name="Last-Mile-Tracker", service_uuid=None):
        self._ble = bluetooth.BLE()
        self._ble.active(True)
        self._ble.irq(self._irq)
        
        self._name = name
        self._connected = False
        self._conn_handle = None
        
        # Register GATT service
        if service_uuid:
            self._register_services(service_uuid)
    
    def _register_services(self, service_uuid):
        """Register Environmental Sensing Service"""
        # Service and characteristic definitions
        ENV_SENSING_UUID = bluetooth.UUID(int(service_uuid, 16))
        SENSOR_CHAR = (
            bluetooth.UUID(0x2A6E),  # Temperature characteristic
            bluetooth.FLAG_READ | bluetooth.FLAG_NOTIFY,
        )
        ENV_SERVICE = (
            ENV_SENSING_UUID,
            (SENSOR_CHAR,),
        )
        
        ((self._sensor_handle,),) = self._ble.gatts_register_services((ENV_SERVICE,))
    
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
    
    def start_advertising(self):
        """Start BLE advertising"""
        payload = self._advertising_payload(self._name)
        self._ble.gap_advertise(100_000, adv_data=payload)
        print(f"Advertising as '{self._name}'")
    
    def _advertising_payload(self, name):
        """Build advertising payload"""
        payload = bytearray()
        
        # Flags
        payload += bytes([0x02, 0x01, 0x06])
        
        # Complete local name
        name_bytes = name.encode()
        payload += bytes([len(name_bytes) + 1, 0x09]) + name_bytes
        
        return payload
    
    def is_connected(self) -> bool:
        return self._connected
    
    def notify(self, data: bytes):
        """Send notification to connected central"""
        if self._connected and self._conn_handle is not None:
            self._ble.gatts_notify(self._conn_handle, self._sensor_handle, data)
