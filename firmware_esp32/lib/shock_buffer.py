class ShockBuffer:
    def __init__(self, size: int = 100) -> None:
        self.size = size
        self.buffer: list[tuple[int, float] | None] = [None] * size
        self.head = 0
        self.count = 0

    def add(self, shock_value: float, timestamp: int) -> None:
        """Add a shock event (value, timestamp_ms)"""
        self.buffer[self.head] = (timestamp, shock_value)
        self.head = (self.head + 1) % self.size
        # Correctly increment count
        if self.count < self.size:
            self.count += 1

    def get_latest(self, n: int = -1) -> list[tuple[int, float]]:
        """Get latest n events, newest first"""
        if n == -1 or n > self.count:
            n = self.count

        result: list[tuple[int, float]] = []
        idx = (self.head - 1 + self.size) % self.size
        for _ in range(n):
            item = self.buffer[idx]
            if item is not None:
                result.append(item)
            idx = (idx - 1 + self.size) % self.size
        return result

    def clear(self) -> None:
        self.head = 0
        self.count = 0
        self.buffer = [None] * self.size
