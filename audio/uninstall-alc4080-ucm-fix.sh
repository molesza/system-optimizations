#!/bin/bash

set -euo pipefail

FILE="/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf"
REMOVE_AUTOSUSPEND_RULE="false"

usage() {
  cat <<'EOF'
Usage: uninstall-alc4080-ucm-fix.sh [--remove-autosuspend-rule]

Removes optional udev autosuspend rule and restores the package-managed UCM file
either via dpkg-divert (if present) or the most recent *.bak.* backup.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-autosuspend-rule) REMOVE_AUTOSUSPEND_RULE="true" ;;
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

if [[ "$REMOVE_AUTOSUSPEND_RULE" == "true" ]]; then
  rule_path="/etc/udev/rules.d/99-alc4080-nosuspend.rules"
  if [[ -f "$rule_path" ]]; then
    rm -f "$rule_path"
    udevadm control --reload-rules
    udevadm trigger
    echo "Removed udev rule: $rule_path"
  else
    echo "udev rule not present: $rule_path"
  fi
fi

if command -v dpkg-divert >/dev/null 2>&1 && dpkg-divert --list "$FILE" 2>/dev/null | grep -q "$FILE"; then
  ts="$(date +%F-%H%M%S)"
  if [[ -f "$FILE" ]]; then
    mv -f "$FILE" "${FILE}.patched.${ts}"
    echo "Moved patched file aside: ${FILE}.patched.${ts}"
  fi
  dpkg-divert --remove --rename "$FILE"
  echo "Removed dpkg diversion and restored distributor file: $FILE"
else
  latest_backup="$(ls -1t "${FILE}.bak."* 2>/dev/null | head -n 1 || true)"
  if [[ -n "$latest_backup" && -f "$latest_backup" ]]; then
    cp -a "$latest_backup" "$FILE"
    echo "Restored from backup: $latest_backup"
  else
    echo "No dpkg diversion found and no backups matching ${FILE}.bak.*"
  fi
fi

cat <<'EOF'

Next steps (run as your desktop user):
  systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service
EOF

