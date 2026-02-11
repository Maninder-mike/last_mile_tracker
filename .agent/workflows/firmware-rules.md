---
description: firmware rules
---

# Firmware Development Rules (Safety-Critical)

These rules are based on the NASA JPL "Power of 10" and adapted for high-reliability MicroPython development on the ESP32.

## 1. Simple Control Flow

- Avoid recursion and complex nested callbacks.
- Use `uasyncio` for cooperative multitasking and keep task logic structured and flat.

## 2. Bounded Loops (Task Health)

- All background tasks (`sensor_task`, `update_task`, `cloud_upload_task`) MUST report health to a central monitor.
- The hardware `Watchdog Timer (WDT)` should only be fed in `maintenance_task` if all monitored tasks have updated their "ticks" within a 60-second window.

## 3. Pre-allocated Memory (Rule 3 Equivalent)

- **Do not allocate memory in the main loop.**
- Use pre-allocated `bytearray`, `memoryview`, and fixed `dict` structures for telemetry and BLE advertising payloads.
- Reuse data structures to prevent heap fragmentation and `MemoryError`.

## 4. Function Length

- Keep functions concise (ideally < 60 lines).
- Break large handlers (like BLE write callbacks) into smaller, testable sub-functions.

## 5. Assertion Density

- Use `assert` statements to validate critical invariants:
  - Configuration ranges (intervals > 0).
  - Data sanity (GPS bounds, battery voltage ranges).
  - Hardware initialization status.

## 6. Small Variable Scope

- Keep variables local to the smallest possible scope.
- Avoid global mutable state; prefer class-encapsulated configuration and diagnostics.

## 7. Status & Return Value Checks

- Always verify the return status of network operations (WiFi, HTTP).
- Check sensor validity flags (e.g., `gps_fix`) before using data.

## 8. Strict Linting

- All code must pass `ruff check` with strict safety and style rules.
- Maintain a zero-warning policy for firmware packages.

## Advanced Optimization & Reliability

## 9. Power Management (Deep Sleep & Radio)

- Use `machine.deepsleep()` for long idle periods (shipment storage).
- Disable WiFi/Bluetooth radios explicitly when not in use to save battery.
- Avoid persistent `active(True)` if a polling pattern (e.g., every 15 min) is sufficient.

### 10. Flash & SD Card Longevity

- Minimize write operations to internal Flash and SD cards.
- Use `lib.sd_logger` with batching or interval-based logging to reduce write cycles.
- Use `micropython.const()` for integer constants to save memory and bytecode space.

### 11. Connectivity Robustness

- Implement exponential backoff for WiFi/HTTP retries to avoid "network storms."
- Always handle "Internal State Errors" by explicitly calling `radio.active(False)` before re-initializing.
- Use a 1-hour "Heartbeat" telemetry upload to verify device liveness during long idle periods.

### 12. Security & Secrets

- **NEVER hardcode credentials.** Use `lib.config` which loads from a protected `config.json`.
- In production, disable the REPL and WebREPL to prevent unauthorized local access.
- All remote configurations must include a `_sig` field for signature verification.

### 13. Performance Hot-Paths

- Use `@micropython.native` or `@micropython.viper` decorators for heavy computation (e.g., signal processing or data packing) to gain near-C speeds.
- Avoid string formatting (`f"{var}"`) in high-frequency loops; use `%` or `.format()` only where necessary, or pre-construct bytearrays.
