# Audio (ALC4080 / MSI X870 Tomahawk)

The MSI MAG X870 TOMAHAWK WIFI exposes its onboard Realtek ALC4080 as **USB audio** (`0db0:cd0e`). Older `alsa-ucm-conf` builds may miss this USB ID in the `If.realtek-alc4080` match, which can lead to PipeWire/WirePlumber repeatedly recreating the sink and GNOME volume UI errors.

## Fix (preferred): upgrade `alsa-ucm-conf`

1. Check your package version and candidate:
   - `apt-cache policy alsa-ucm-conf`
2. Upgrade if a newer build is available:
   - `sudo apt update`
   - `sudo apt install --only-upgrade alsa-ucm-conf`
3. Verify the fix is present:
   - `grep -n "cd0e" /usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf`
4. Restart the user audio stack:
   - `systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service`

## Fix (fallback): patch `USB-Audio.conf` (matches upstream)

- Install: `sudo ./audio/install-alc4080-ucm-fix.sh`
- Persist across package updates (optional): `sudo ./audio/install-alc4080-ucm-fix.sh --divert`
- If you suspect USB resets, disable autosuspend for this device (optional): `sudo ./audio/install-alc4080-ucm-fix.sh --disable-autosuspend`

Stability check:
`for i in {1..15}; do pactl list sinks short | grep -i usb | awk '{print $1,$2}'; sleep 2; done`

Rollback:
- `sudo ./audio/uninstall-alc4080-ucm-fix.sh`
- If you used autosuspend disabling: `sudo ./audio/uninstall-alc4080-ucm-fix.sh --remove-autosuspend-rule`

