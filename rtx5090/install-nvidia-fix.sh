#!/bin/bash
# Install NVIDIA RTX 5090 stability fix for Pop!_OS
# Addresses Xid 13/69 errors caused by excessive GPU clocks
# Also installs shutdown script for clean dual-boot handoff

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/nvidia-powerd-fix.service"
SHUTDOWN_SCRIPT="$SCRIPT_DIR/scripts/nvidia-reset.shutdown"

echo "Installing NVIDIA RTX 5090 stability fix..."

# Copy service file
sudo cp "$SERVICE_FILE" /etc/systemd/system/

# Reload systemd and enable
sudo systemctl daemon-reload
sudo systemctl enable nvidia-powerd-fix.service

# Install shutdown script for dual-boot compatibility
if [ -f "$SHUTDOWN_SCRIPT" ]; then
    echo "Installing shutdown script for dual-boot compatibility..."
    sudo cp "$SHUTDOWN_SCRIPT" /lib/systemd/system-shutdown/
    sudo chmod +x /lib/systemd/system-shutdown/nvidia-reset.shutdown
fi

# Apply immediately
sudo nvidia-smi -pm 1
sudo nvidia-smi -lgc 180,2407

echo ""
echo "Fix installed successfully!"
echo "- Persistence mode: ENABLED"
echo "- GPU clock limits: 180-2407 MHz"
echo "- Shutdown script: Resets GPU state for clean dual-boot"
echo ""
echo "The fix will be applied automatically on every boot."
echo "GPU state will be reset on shutdown/reboot for Windows compatibility."
echo ""
echo "To verify: nvidia-smi -q | grep -E '(Persistence|Clocks)'"
echo "To uninstall: sudo systemctl disable nvidia-powerd-fix.service"
