import os
import time


class Logger:
    MAX_SIZE = 10 * 1024  # 10KB
    LOG_FILE = "log.txt"
    BUFFER_SIZE = 5

    _buffer = []
    _boot_time = time.ticks_ms()
    SILENT_PERIOD_MS = 3000

    @staticmethod
    def log(message):
        try:
            timestamp = time.ticks_ms()
            entry = f"[{timestamp}] {message}"

            # Print to serial if past silent period
            if time.ticks_diff(timestamp, Logger._boot_time) > Logger.SILENT_PERIOD_MS:
                print(entry)

            # Add to buffer
            Logger._buffer.append(entry)

            if len(Logger._buffer) >= Logger.BUFFER_SIZE:
                Logger.flush()

        except Exception as e:
            print(f"Logger Error: {e}")

    @staticmethod
    def flush():
        if not Logger._buffer:
            return

        try:
            # Check rotation
            try:
                stat = os.stat(Logger.LOG_FILE)
                if stat[6] > Logger.MAX_SIZE:
                    try:
                        os.remove("log.bak")
                    except OSError:
                        pass
                    os.rename(Logger.LOG_FILE, "log.bak")
            except OSError:
                pass

            # Write batch
            with open(Logger.LOG_FILE, "a") as f:
                for entry in Logger._buffer:
                    f.write(entry + "\n")

            Logger._buffer.clear()
        except Exception as e:
            print(f"Flush Error: {e}")
