# ST7789 TFT Display Driver for ESP32-C6
from machine import Pin, SPI
import struct
import time

# Minimal pure python ST7789 driver since native module might not be available
# Based on common MicroPython implementations


class ST7789:
    def __init__(self, spi, width, height, reset, dc, cs, backlight):
        self.width = width
        self.height = height
        self.spi = spi
        self.reset = reset
        self.dc = dc
        self.cs = cs
        self.backlight = backlight

        self.cs.init(self.cs.OUT, value=1)
        self.dc.init(self.dc.OUT, value=0)
        self.reset.init(self.reset.OUT, value=1)

        self.init()

    def init(self):
        self.reset.value(0)
        time.sleep_ms(50)
        self.reset.value(1)
        time.sleep_ms(150)

        self._write(0x11)  # Sleep out
        time.sleep_ms(150)

        self._write(0x36, b"\x00")  # MADCTL: RGB
        self._write(0x3A, b"\x55")  # COLMOD: 16-bit
        self._write(0xB2, b"\x0c\x0c\x00\x33\x33")  # PORCTRL
        self._write(0xB7, b"\x35")  # GCTRL
        self._write(0xBB, b"\x19")  # VCOMS
        self._write(0xC0, b"\x2c")  # LCMCTRL
        self._write(0xC2, b"\x01")  # VDVVRHEN
        self._write(0xC3, b"\x12")  # VRHS
        self._write(0xC4, b"\x20")  # VDVSET
        self._write(0xC6, b"\x0f")  # FRMCTR2
        self._write(0xD0, b"\xa4\xa1")  # PWCTRL1
        self._write(0x21)  # Inversion on
        self._write(0xE0, b"\xd0\x04\x0d\x11\x13\x2b\x3f\x54\x4c\x18\x0d\x0b\x1f\x23")  # PVGAMCTRL
        self._write(0xE1, b"\xd0\x04\x0c\x11\x13\x2c\x3f\x44\x51\x2f\x1f\x1f\x20\x23")  # NVGAMCTRL
        self._write(0x29)  # Display on

    def _write(self, command, data=None):
        self.cs.value(0)
        self.dc.value(0)
        self.spi.write(bytearray([command]))
        if data:
            self.dc.value(1)
            self.spi.write(data)
        self.cs.value(1)

    def fill(self, color):
        # 16-bit color (565)
        # Separate high/low bytes
        c_hi = (color >> 8) & 0xFF
        c_lo = color & 0xFF

        self._set_window(0, 0, self.width - 1, self.height - 1)

        # Write chunks
        chunk_size = 1024
        chunk = bytearray([c_hi, c_lo] * (chunk_size // 2))

        total_pixels = self.width * self.height
        bytes_remaining = total_pixels * 2

        self.cs.value(0)
        self.dc.value(1)
        while bytes_remaining > 0:
            to_write = min(bytes_remaining, chunk_size)
            self.spi.write(chunk[:to_write])
            bytes_remaining -= to_write
        self.cs.value(1)

    def _set_window(self, x0, y0, x1, y1):
        self._write(0x2A, struct.pack(">HH", x0, x1))
        self._write(0x2B, struct.pack(">HH", y0, y1))
        self._write(0x2C)


class Display:
    """1.69" TFT ST7789 Display (240x280)"""

    # ESP32-C6 SPI pins for ST7789
    PIN_SCL = 10  # SCK/CLK
    PIN_SDA = 11  # MOSI/SDA
    PIN_DC = 8  # Data/Command
    PIN_RES = 9  # Reset
    PIN_CS = 12  # Chip Select
    PIN_BLK = 13  # Backlight

    WIDTH = 240
    HEIGHT = 280

    # Colors
    BLACK = 0x0000
    WHITE = 0xFFFF
    RED = 0xF800
    GREEN = 0x07E0
    BLUE = 0x001F
    CYAN = 0x07FF
    YELLOW = 0xFFE0

    def __init__(self):
        # SPI bus (SPI 1)
        self._spi = SPI(1, baudrate=40000000, sck=Pin(self.PIN_SCL), mosi=Pin(self.PIN_SDA))

        self._tft = ST7789(
            self._spi,
            self.WIDTH,
            self.HEIGHT,
            reset=Pin(self.PIN_RES, Pin.OUT),
            dc=Pin(self.PIN_DC, Pin.OUT),
            cs=Pin(self.PIN_CS, Pin.OUT),
            backlight=Pin(self.PIN_BLK, Pin.OUT),
        )
        self.backlight(True)

    def clear(self, color=BLACK):
        self._tft.fill(color)

    def show_stats(self, speed: float, temp: float, shock: int, gps_fix: bool):
        """Display live stats in large font"""
        self.clear()

        # Note: text rendering needs a font/framebuffer.
        # Since standard MicroPython doesn't have vector fonts easily,
        # we might need to use a library like 'writer' or just built-in 'framebuf'
        # if using a driver that subclasses framebuf.
        #
        # For this MVP without external font files, we'll assume basic text isn't easy
        # on bare ST7789 unless we bring in a font library.
        # OR we use a driver that inherits framebuf.
        #
        # Given limitations, let's just color fill for status blocks for now
        # until we import a font library.
        # Top block: Speed (Cyan)
        # Mid block: Temp (Yellow)
        # Bottom: Shock (Red/Green)

        # This is a PLACEHOLDER implementation.
        # Real text requires a font file (e.g. vga1_16x16.py) to be uploaded.
        pass

    def text(self, msg, x, y, color=WHITE):
        # Placeholder for text rendering
        pass

    def backlight(self, on: bool):
        self._tft.backlight.value(1 if on else 0)
