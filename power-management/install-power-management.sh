#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SLEEP_CONF_SRC="${SCRIPT_DIR}/disable-sleep.conf"
UDEV_RULE_SRC="${SCRIPT_DIR}/90-disable-usb4-wake.rules"
SERVICE_SRC="${SCRIPT_DIR}/system76-performance.service"

SLEEP_CONF_DST_DIR="/etc/systemd/sleep.conf.d"
SLEEP_CONF_DST="${SLEEP_CONF_DST_DIR}/disable-sleep.conf"
UDEV_RULE_DST="/etc/udev/rules.d/90-disable-usb4-wake.rules"
SERVICE_DST="/etc/systemd/system/system76-performance.service"

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root (try: sudo $0)" >&2
  exit 1
fi

for f in "$SLEEP_CONF_SRC" "$UDEV_RULE_SRC" "$SERVICE_SRC"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

mkdir -p "$SLEEP_CONF_DST_DIR"
install -m 0644 "$SLEEP_CONF_SRC" "$SLEEP_CONF_DST"
install -m 0644 "$UDEV_RULE_SRC" "$UDEV_RULE_DST"
install -m 0644 "$SERVICE_SRC" "$SERVICE_DST"

udevadm control --reload-rules
udevadm trigger

systemctl daemon-reload
systemctl enable --now system76-performance.service

cat <<'EOF'
Installed:
  - /etc/systemd/sleep.conf.d/disable-sleep.conf
  - /etc/udev/rules.d/90-disable-usb4-wake.rules
  - /etc/systemd/system/system76-performance.service (enabled)

Next steps (optional, run as your desktop user) to use "screen blank only":
  gsettings set org.gnome.desktop.session idle-delay 300
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

Reboot recommended.
EOF

