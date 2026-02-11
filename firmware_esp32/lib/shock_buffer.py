class ShockBuffer:
    def __init__(self, size=100):
        self.size = size
        self.buffer = [None] * size
        self.head = 0
        self.count = 0

    def add(self, shock_value, timestamp):
        """Add a shock event (value, timestamp_ms)"""
        self.buffer[self.head] = (timestamp, shock_value)
        self.head = (self.head + 1) % self.size
        if self.count < self.size:
            self.count += 1

    def get_latest(self, n=None):
        """Get latest n events, newest first"""
        if n is None or n > self.count:
            n = self.count

        result = []
        idx = (self.head - 1 + self.size) % self.size
        for _ in range(n):
            if self.buffer[idx] is not None:
                result.append(self.buffer[idx])
            idx = (idx - 1 + self.size) % self.size
        return result

    def clear(self):
        self.head = 0
        self.count = 0
        self.buffer = [None] * self.size
