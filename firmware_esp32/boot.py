# boot.py - ESP32-C6 Boot Configuration
# This runs before main.py

import esp
import gc

# Disable debug output to free up UART
esp.osdebug(None)

# Run garbage collection to free memory
gc.collect()

print("Milow-Tracker booting...")
