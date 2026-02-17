from machine import Pin, PWM
import time
import uasyncio as asyncio


class Buzzer:
    def __init__(self, pin_num: int | None) -> None:
        self.pin_num = pin_num
        self.pwm: PWM | None = None
        if pin_num is not None:
            self.pwm = PWM(Pin(pin_num), freq=2000, duty=0)

    def beep(self, duration_ms: int = 100, freq: int = 2000) -> None:
        """Blocking beep"""
        if not self.pwm:
            return
        self.pwm.freq(freq)
        self.pwm.duty(512)  # 50% duty cycle
        time.sleep_ms(duration_ms)  # type: ignore
        self.pwm.duty(0)

    async def beep_async(self, duration_ms: int = 100, freq: int = 2000) -> None:
        """Non-blocking beep"""
        if not self.pwm:
            return
        self.pwm.freq(freq)
        self.pwm.duty(512)
        await asyncio.sleep_ms(duration_ms)
        self.pwm.duty(0)

    async def play_melody(self, notes: list[tuple[int, int]]) -> None:
        """Play a list of (freq, duration) tuples"""
        if not self.pwm:
            return
        for freq, duration in notes:
            if freq == 0:
                self.pwm.duty(0)
            else:
                self.pwm.freq(freq)
                self.pwm.duty(512)
            await asyncio.sleep_ms(duration)
            self.pwm.duty(0)
            await asyncio.sleep_ms(50)  # Tiny gap between notes

    async def alarm(self) -> None:
        """Shock alarm pattern"""
        # 3 fast high-pitched beeps
        for _ in range(3):
            await self.beep_async(100, 3000)
            await asyncio.sleep_ms(50)

    def off(self) -> None:
        if self.pwm:
            self.pwm.duty(0)
            self.pwm.deinit()
