#!/bin/bash

set -euo pipefail

FILE="/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf"
DISABLE_AUTOSUSPEND="false"
USE_DIVERT="false"

usage() {
  cat <<'EOF'
Usage: install-alc4080-ucm-fix.sh [--divert] [--disable-autosuspend]

Adds MSI X870 Tomahawk onboard USB audio ID (0db0:cd0e) to the Realtek ALC4080
match in /usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf.

Options:
  --divert              Use dpkg-divert so the patch survives package updates.
  --disable-autosuspend Install a udev rule disabling autosuspend for 0db0:cd0e.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --divert) USE_DIVERT="true" ;;
    --disable-autosuspend) DISABLE_AUTOSUSPEND="true" ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
  shift
done

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root (try: sudo $0 ...)" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Not found: $FILE" >&2
  exit 1
fi

if [[ "$USE_DIVERT" == "true" ]]; then
  if ! command -v dpkg-divert >/dev/null 2>&1; then
    echo "dpkg-divert not found; install dpkg or run without --divert." >&2
    exit 1
  fi

  if ! dpkg-divert --list "$FILE" 2>/dev/null | grep -q "$FILE"; then
    echo "Creating dpkg diversion for: $FILE"
    dpkg-divert --add --rename --divert "${FILE}.distrib" "$FILE"
    install -m 0644 "${FILE}.distrib" "$FILE"
  else
    echo "dpkg diversion already present for: $FILE"
  fi
fi

if grep -q "cd0e" "$FILE"; then
  echo "Already present: 0db0:cd0e in $FILE"
else
  ts="$(date +%F-%H%M%S)"
  backup="${FILE}.bak.${ts}"
  cp -a "$FILE" "$backup"
  echo "Backup created: $backup"

  block_preview="$(sed -n '/If\.realtek-alc4080 {/,/True\.Define\.ProfileName "Realtek\/ALC4080"/p' "$FILE" || true)"
  if ! printf '%s\n' "$block_preview" | grep -q 'If\.realtek-alc4080'; then
    echo "Could not locate If.realtek-alc4080 block in $FILE" >&2
    exit 1
  fi

  if printf '%s\n' "$block_preview" | grep -q "|b202|d1d7"; then
    sed -i '/If\.realtek-alc4080 {/,/True\.Define\.ProfileName "Realtek\/ALC4080"/ s/|b202|d1d7/|b202|cd0e|d1d7/' "$FILE"
  else
    sed -i '/If\.realtek-alc4080 {/,/True\.Define\.ProfileName "Realtek\/ALC4080"/ s/0db0:(/0db0:(cd0e|/' "$FILE"
  fi

  if ! grep -q "cd0e" "$FILE"; then
    echo "Patch failed: cd0e not found after edit. Restore from $backup" >&2
    exit 1
  fi

  echo "Patched successfully:"
  grep -n "cd0e" "$FILE" | head -n 5
fi

if [[ "$DISABLE_AUTOSUSPEND" == "true" ]]; then
  rule_path="/etc/udev/rules.d/99-alc4080-nosuspend.rules"
  cat >"$rule_path" <<'EOF'
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0db0", ATTR{idProduct}=="cd0e", TEST=="power/control", ATTR{power/control}="on"
EOF
  chmod 0644 "$rule_path"
  udevadm control --reload-rules
  udevadm trigger
  echo "Installed udev rule: $rule_path"
fi

cat <<'EOF'

Next steps (run as your desktop user):
  systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service

Stability check:
  for i in {1..15}; do pactl list sinks short | grep -i usb | awk '{print $1,$2}'; sleep 2; done
EOF
