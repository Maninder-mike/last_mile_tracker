import bluetooth
import time


print("Init BLE...")
ble = bluetooth.BLE()
ble.active(True)

def adv_payload(name):
    payload = bytearray()
    payload += bytes([0x02, 0x01, 0x06])
    name_bytes = name.encode()
    payload += bytes([len(name_bytes) + 1, 0x09]) + name_bytes
    return payload

payload = adv_payload("ESP-TEST")
print("Advertising as 'ESP-TEST'...")
# 100ms interval
ble.gap_advertise(100000, adv_data=payload)

print("Looping (Ctrl+C to stop)...")
var = 0
while True:
    print(".", end="")
    time.sleep(1)
