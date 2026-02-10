# ESP32-C6 Firmware (MicroPython)

This directory contains the MicroPython firmware for the Last Mile Tracker hardware. It is designed to run asynchronously using `uasyncio`, ensuring efficient handling of BLE advertising, sensor readings (MPU-6050, DS18B20, GPS), and display updates.

## Hardware Requirements

- **Microcontroller**: ESP32-C6 (RISC-V)
- **Display**: ST7789 (1.69" TFT) via SPI
- **IMU**: MPU-6050 (I2C)
- **Temp Sensor**: DS18B20 (1-Wire)
- **GPS**: NEO-6M (UART)

## Pin Configuration

| Component | ESP32-C6 Pin |
| :--- | :--- |
| **SDA** (I2C) | GPIO 6 |
| **SCL** (I2C) | GPIO 7 |
| **TX** (GPS) | GPIO 21 |
| **RX** (GPS) | GPIO 20 |
| **DS18B20** | GPIO 4 |
| **NeoPixel** | GPIO 8 |
| **SPI CS** | GPIO 10 |
| **SPI DC** | GPIO 9 |
| **SPI CLK** | GPIO 12 |
| **SPI MOSI** | GPIO 11 |

## Setup Instructions

1. **Flash MicroPython**:
    Ensure your device is flashed with a MicroPython build supporting ESP32-C6.

2. **Upload Files**:
    Use `mpremote`, `ampy`, or Thonny to upload all `.py` files to the root of the device.

    ```bash
    mpremote cp -r *.py :
    mpremote cp -r lib/ :lib/
    ```

3. **Run**:
    Reset the device. `main.py` will start automatically.

## Development

- **Linting**: Run `ruff check .` to verify code quality (enforced by CI).
- **Architecture**: The `main.py` orchestrates tasks via `uasyncio.gather()`. Avoid blocking code in the main loop.
