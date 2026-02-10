#!/bin/bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
MPREMOTE="python3 -m mpremote"
PORT_PATTERN="/dev/cu.usbmodem*"
MAX_RETRIES=3
RETRY_DELAY=2

# Files to upload (relative paths)
FILES=(
    "boot.py:boot.py"
    "main.py:main.py"
    "lib/wifi_manager.py:lib/wifi_manager.py"
    "lib/ble_advertising.py:lib/ble_advertising.py"
    "lib/ble_ota.py:lib/ble_ota.py"
    "lib/sensors.py:lib/sensors.py"
    "lib/st7789_display.py:lib/st7789_display.py"
    "lib/sd_logger.py:lib/sd_logger.py"
    "lib/config.py:lib/config.py"
    "lib/diagnostics.py:lib/diagnostics.py"
    "lib/logger.py:lib/logger.py"
    "lib/shock_buffer.py:lib/shock_buffer.py"
)

# ─── Helpers ─────────────────────────────────────────────────────────────────
info()  { echo "  ℹ  $*"; }
ok()    { echo "  ✅ $*"; }
fail()  { echo "  ❌ $*"; }
warn()  { echo "  ⚠️  $*"; }

# ─── Detect Port ─────────────────────────────────────────────────────────────
detect_port() {
    local port
    port=$(ls $PORT_PATTERN 2>/dev/null | head -n 1)
    if [ -z "$port" ]; then
        fail "No ESP32 found (looking for $PORT_PATTERN)"
        echo ""
        echo "  Troubleshooting:"
        echo "    1. Check the USB cable is connected"
        echo "    2. Try a different USB port"
        echo "    3. Check 'ls /dev/cu.usb*' manually"
        exit 1
    fi
    echo "$port"
}

# ─── Check for port conflicts ───────────────────────────────────────────────
check_port_conflicts() {
    local port="$1"
    local conflicts
    conflicts=$(lsof "$port" 2>/dev/null | tail -n +2 || true)
    if [ -n "$conflicts" ]; then
        warn "Another process is using $port:"
        echo "$conflicts" | awk '{print "       PID " $2 " (" $1 ")"}'
        echo ""
        read -r -p "  Kill conflicting processes? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo "$conflicts" | awk '{print $2}' | sort -u | xargs kill -9 2>/dev/null || true
            sleep 1
            ok "Killed conflicting processes"
        else
            fail "Cannot proceed with port in use"
            exit 1
        fi
    fi
}

# ─── Interrupt running code ─────────────────────────────────────────────────
interrupt_board() {
    local port="$1"
    info "Sending interrupt to break any running code..."
    # Send Ctrl+C (0x03) twice via the serial port to interrupt running code
    printf '\x03\x03' > "$port" 2>/dev/null || true
    sleep 0.5
}

# ─── Build the chained mpremote command ──────────────────────────────────────
build_upload_command() {
    local port="$1"
    local cmd="$MPREMOTE connect $port"

    # Create lib directory first (safely)
    cmd+=" + run tools/ensure_lib.py"

    # Chain all file copy operations
    for entry in "${FILES[@]}"; do
        local src="${entry%%:*}"
        local dst="${entry##*:}"
        cmd+=" + cp $src :$dst"
    done

    # Reset the board after upload
    cmd+=" + reset"

    echo "$cmd"
}

# ─── Main ────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ESP32 Firmware Flash Tool              ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Detect port
info "Detecting ESP32..."
PORT=$(detect_port)
ok "Found ESP32 at $PORT"

# 2. Check for port conflicts
check_port_conflicts "$PORT"

# 3. Attempt upload with retries
for attempt in $(seq 1 $MAX_RETRIES); do
    echo ""
    info "Upload attempt $attempt/$MAX_RETRIES..."

    # Interrupt any running code before connecting
    interrupt_board "$PORT"

    # Build the single chained command
    UPLOAD_CMD=$(build_upload_command "$PORT")

    info "Uploading all files in a single connection..."
    if eval "$UPLOAD_CMD" 2>&1; then
        echo ""
        ok "All files uploaded successfully!"
        ok "Board has been reset. Firmware is running."
        echo ""
        echo "  View logs with:"
        echo "    $MPREMOTE connect $PORT repl"
        echo ""
        exit 0
    fi

    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
        warn "Attempt $attempt failed. Retrying in ${RETRY_DELAY}s..."
        warn "Try pressing the RST button on the ESP32 now."
        sleep $RETRY_DELAY
    fi
done

# All retries exhausted
echo ""
fail "Failed after $MAX_RETRIES attempts."
echo ""
echo "  The board may be stuck in a tight loop. Try:"
echo ""
echo "  Option A — Physical reset:"
echo "    1. Hold BOOT button"
echo "    2. Press RST button"
echo "    3. Release both"
echo "    4. Re-run this script immediately"
echo ""
echo "  Option B — Full reflash via Thonny:"
echo "    1. Open Thonny"
echo "    2. Go to Tools → Options → Interpreter"
echo "    3. Click 'Install or update MicroPython (esptool)'"
echo "    4. Check 'Erase all flash before installing'"
echo "    5. Install, then close Thonny and re-run this script"
echo ""
echo "  Option C — Full reflash via CLI:"
echo "    python3 -m esptool --port $PORT erase_flash"
echo "    python3 -m esptool --port $PORT --baud 460800 write_flash -z 0x1000 <micropython.bin>"
echo ""
exit 1
