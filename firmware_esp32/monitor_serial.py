import serial
import sys

port = '/dev/cu.usbmodem1101'
baud = 115200

print(f"Opening {port} at {baud}...")
try:
    with serial.Serial(port, baud, timeout=1) as ser:
        print("Connected. Press Ctrl+C to stop.")
        while True:
            line = ser.readline()
            if line:
                print(line.decode('utf-8', errors='replace').strip())
except Exception as e:
    print(f"Error: {e}")
