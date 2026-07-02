#!/bin/bash

# Find adb executable
ADB="adb"
if ! command -v adb &> /dev/null; then
    if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        ADB="$HOME/Library/Android/sdk/platform-tools/adb"
    else
        echo "Error: adb command not found and not found in default Android SDK path."
        exit 1
    fi
fi

# Check if any device is connected
DEVICES=$($ADB devices | grep -v "List" | grep "device")
if [ -z "$DEVICES" ]; then
    echo "Error: No Android device is attached or authorized."
    exit 1
fi

PACKAGE_NAME="maninder.co.in.last_mile_tracker"
LOG_DIR="logs"
OUTPUT_FILE="$LOG_DIR/device_app_logs.txt"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "Pulling app logs from connected device..."
$ADB shell "run-as $PACKAGE_NAME cat app_flutter/app_logs.txt" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    SIZE=$(wc -c < "$OUTPUT_FILE" | xargs)
    echo "Success! Logs saved to $OUTPUT_FILE ($SIZE bytes)"
else
    echo "Error: Failed to retrieve logs from device."
    exit 1
fi
