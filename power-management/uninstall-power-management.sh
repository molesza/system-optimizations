#!/bin/bash

set -euo pipefail

SLEEP_CONF_DST="/etc/systemd/sleep.conf.d/disable-sleep.conf"
UDEV_RULE_DST="/etc/udev/rules.d/90-disable-usb4-wake.rules"
SERVICE_DST="/etc/systemd/system/system76-performance.service"

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root (try: sudo $0)" >&2
  exit 1
fi

if systemctl list-unit-files system76-performance.service >/dev/null 2>&1; then
  systemctl disable --now system76-performance.service >/dev/null 2>&1 || true
fi

rm -f "$SLEEP_CONF_DST" "$UDEV_RULE_DST" "$SERVICE_DST"

udevadm control --reload-rules
udevadm trigger
systemctl daemon-reload

cat <<'EOF'
Removed:
  - /etc/systemd/sleep.conf.d/disable-sleep.conf
  - /etc/udev/rules.d/90-disable-usb4-wake.rules
  - /etc/systemd/system/system76-performance.service

Reboot recommended.
EOF

