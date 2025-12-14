# Audio Investigation Report

**Date:** 2025-12-14
**System:** Pop!_OS 22.04 LTS
**Kernel:** 6.17.4-76061704-generic (System76)

---

## Hardware Affected

| Component | Model | USB ID | Notes |
|-----------|-------|--------|-------|
| **Motherboard** | MSI MAG X870 TOMAHAWK WIFI | - | Uses USB-based audio |
| **Audio Codec** | Realtek ALC4080 | `0db0:cd0e` | USB Audio (not traditional HD Audio) |
| **CPU** | AMD Ryzen 7 9800X3D | - | |
| **GPU** | NVIDIA RTX 5090 | - | Has HDMI audio (disabled) |

---

## Problem Description

### Symptoms
1. **Audio icon disappears/reappears** in GNOME taskbar intermittently
2. **System volume changes by itself** without user input
3. **YouTube video playback slowdowns** in Firefox
4. Firefox logs show: `NS_ERROR_DOM_MEDIA_RANGE_ERR`
5. GNOME logs show: `gvc_mixer_ui_device_get_id: assertion 'GVC_IS_MIXER_UI_DEVICE (device)' failed`
6. WirePlumber logs show: `Object activation aborted: proxy destroyed`

### Observed Behavior
PipeWire/WirePlumber is **constantly recreating the USB audio device**. The sink ID changes approximately every 2-4 seconds:

```
12:44:36 - 2108
12:44:38 - 2133
12:44:40 - 2158
...
12:46:34 - 2770
```

In 2 minutes, the sink ID changed ~330 times. This causes:
- Audio interruptions
- GNOME volume control failures
- Application audio sync issues

---

## Root Cause Analysis

### Finding 1: X870 TOMAHAWK Uses USB Audio (Not HD Audio)

The MSI MAG X870 TOMAHAWK WIFI uses **Realtek ALC4080**, which is a **USB-based audio codec**, not a traditional HD Audio codec.

```bash
$ lsusb | grep audio
Bus 001 Device 005: ID 0db0:cd0e Micro Star International USB Audio
```

The AMD HD Audio Controller at `73:00.6` shows "no codecs found" - this is **expected behavior** because the motherboard routes audio through USB.

### Finding 2: Missing UCM Configuration

The **ALSA UCM (Use Case Manager)** configuration does NOT include the X870 TOMAHAWK.

**File:** `/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf`

**Current regex for ALC4080 devices:**
```
Regex "USB((0414:a0(0b|0e|1[0124]))|(0b05:(19(84|9[69])|1a(16|2[07]|5[23c])))|(0db0:(005a|151f|1feb|3130|36e7|419c|422d|4240|62a4|6c[0c]9|7696|82c7|8af7|961e|a073|a47c|a74b|b202|d1d7|d6e7)))"
```

**MSI boards included:**
- `0db0:005a` - MSI MPG Z690 CARBON WIFI
- `0db0:151f` - MSI X570S EDGE MAX WIFI
- `0db0:36e7` - MSI MAG B650I Edge WiFi
- `0db0:961e` - MSI MEG X670E ACE
- `0db0:b202` - MSI MAG Z690 Tomahawk Wifi
- `0db0:d6e7` - MSI MPG X670E Carbon Wifi
- ... and others

**Missing:**
- `0db0:cd0e` - **MSI MAG X870 TOMAHAWK WIFI** (this system)

Without UCM matching, PipeWire/WirePlumber may use fallback handling, causing device instability.

**Upstream status:** this exact ID was later added upstream to the `If.realtek-alc4080` match in `alsa-ucm-conf`. If your distro build predates that change, upgrade `alsa-ucm-conf` or apply the local patch below.

### Finding 3: GNOME Volume Control Bug

There's a known bug in `libgnome-volume-control` that causes assertion failures when audio devices are recreated:
- [GNOME GitLab Issue #19](https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/issues/19)
- [Pop!_OS Issue #3325](https://github.com/pop-os/pop/issues/3325)

### Finding 4: NVIDIA HDMI Audio Was Incorrectly Blacklisted

Previously, `/etc/modprobe.d/blacklist-nvidia-hdmi.conf` contained:
```
blacklist snd_hda_intel
```

This disabled ALL HDA audio. Fixed to use targeted HDMI codec blocking:
```
install snd_hda_codec_hdmi /bin/true
```

---

## Software Versions

```
alsa-ucm-conf: 1.2.8-1pop1~1709769747~22.04~16ff971
pipewire: 1.0.2~1707732619~22.04~b8b871b
wireplumber: 0.4.17~1701792620~22.04~e8b4d60
```

---

## Proposed Solution

### Fix 1 (best): Upgrade `alsa-ucm-conf`

If your distro has a build that includes the upstream `0db0:cd0e` change, prefer upgrading instead of local patching:

```bash
apt-cache policy alsa-ucm-conf
sudo apt update
sudo apt install --only-upgrade alsa-ucm-conf
```

Verify the fix is present:

```bash
grep -n "cd0e" /usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf
```

Restart the user audio stack:

```bash
systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service
```

### Fix 2 (fallback): Patch `USB-Audio.conf` like upstream

Option A: use the repo installer:

```bash
sudo ./audio/install-alc4080-ucm-fix.sh
```

Option B: manual patch (only if missing), with backup:

```bash
FILE=/usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf

sudo cp -a "$FILE" "$FILE.bak.$(date +%F-%H%M%S)"
if ! grep -q "cd0e" "$FILE"; then
  sudo sed -i '/If\.realtek-alc4080 {/,/True\.Define\.ProfileName \"Realtek\/ALC4080\"/ s/|b202|d1d7/|b202|cd0e|d1d7/' "$FILE"
fi

grep -n "cd0e" "$FILE"
systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service
```

### Make it survive updates (optional): dpkg diversion

```bash
sudo ./audio/install-alc4080-ucm-fix.sh --divert
```

### Test stability (should show a stable sink ID)

```bash
for i in {1..15}; do pactl list sinks short | grep -i usb | awk '{print $1,$2}'; sleep 2; done
```

### Caveats

1. Editing `/usr/share/...` is **package-managed**; use `--divert` if you want the patch to survive updates.
2. If the sink still flaps after UCM is fixed, check for **real USB resets / re-enumeration** (see below).

### If the sink is still recreated: check for USB resets + disable autosuspend (optional)

```bash
sudo journalctl -k -f | grep -Ei "0db0|cd0e|usb|snd-usb-audio"
sudo udevadm monitor --kernel --udev --subsystem-match=usb
```

If you see resets/disconnects for `0db0:cd0e`, try disabling autosuspend for this device:

```bash
sudo ./audio/install-alc4080-ucm-fix.sh --disable-autosuspend
```

Rollback:

```bash
sudo ./audio/uninstall-alc4080-ucm-fix.sh --remove-autosuspend-rule
```

---

## Upstream Status

- Upstream tracking: https://github.com/alsa-project/alsa-ucm-conf/issues/455
- Upstream fix: https://github.com/alsa-project/alsa-ucm-conf/commit/f6498fbe4c74a897c0df30ba30c5390a9d508ecd

If Pop!_OS still ships an older build, request a backport/upgrade (attach `apt-cache policy alsa-ucm-conf` output).

---

## Other Configurations Made

### 1. NVIDIA HDMI Audio Blocking
**File:** `/etc/modprobe.d/blacklist-nvidia-hdmi.conf`
```
# Disable NVIDIA HDMI audio while keeping onboard Realtek ALC4080 working
install snd_hda_codec_hdmi /bin/true
```

### 2. RTL8127A Network Firmware
Downloaded missing firmware to suppress initramfs warning:
```bash
sudo curl -o /lib/firmware/rtl_nic/rtl8127a-1.fw "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/rtl_nic/rtl8127a-1.fw"
```

### 3. Unnecessary Config to Remove
**File:** `/etc/modprobe.d/alsa-realtek-fix.conf`

This was created during troubleshooting but is not needed (the "no codecs found" message for AMD HD Audio is expected):
```bash
sudo rm /etc/modprobe.d/alsa-realtek-fix.conf
```

---

## Workarounds Tried (Did Not Solve)

| Workaround | Result |
|------------|--------|
| Clear WirePlumber state (`~/.local/state/wireplumber/`) | No improvement |
| Disable ACP, enable UCM in WirePlumber config | No improvement |
| Restart PipeWire/WirePlumber services | Temporary, issue returns |

---

## Diagnostic Commands

```bash
# Check USB audio device
lsusb | grep "0db0:cd0e"

# Check sound cards
cat /proc/asound/cards

# Monitor sink ID stability (should NOT change rapidly)
for i in {1..15}; do pactl list sinks short | grep -i usb | awk '{print $1,$2}'; sleep 2; done

# Check WirePlumber errors
journalctl --user -u wireplumber --since "5 minutes ago" | grep -i error

# Check GNOME volume control errors
journalctl -b | grep "gvc_mixer"

# Verify UCM config has your board
grep "cd0e" /usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf

# Watch for USB resets / re-enumeration events
sudo journalctl -k -f | grep -Ei "0db0|cd0e|usb|snd-usb-audio"
sudo udevadm monitor --kernel --udev --subsystem-match=usb
```

---

## References

- [ALC4080 UCM Support Issue - GitHub](https://github.com/alsa-project/alsa-ucm-conf/issues/455)
- [Upstream commit adding `0db0:cd0e` - GitHub](https://github.com/alsa-project/alsa-ucm-conf/commit/f6498fbe4c74a897c0df30ba30c5390a9d508ecd)
- [ALC4080 General Discussion - GitHub](https://github.com/alsa-project/alsa-ucm-conf/issues/541)
- [GNOME libgnome-volume-control Issue #19](https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/issues/19)
- [Pop!_OS Audio Issues #3325](https://github.com/pop-os/pop/issues/3325)
- [WirePlumber ArchWiki](https://wiki.archlinux.org/title/WirePlumber)
- [PipeWire ArchWiki](https://wiki.archlinux.org/title/PipeWire)
- [MSI X870 TOMAHAWK Specs - KitGuru](https://www.kitguru.net/components/motherboard/leo-waldock/msi-mag-x870-tomahawk-review/)

---

## Summary

The MSI MAG X870 TOMAHAWK WIFI (`0db0:cd0e`) was missing from the installed `alsa-ucm-conf` UCM match list for Realtek ALC4080 USB audio devices, which can cause PipeWire/WirePlumber to repeatedly recreate the sink and break GNOME’s volume UI.

**Recommended action:** Upgrade `alsa-ucm-conf` to a build containing the upstream fix, or apply the local patch (optionally with `dpkg-divert`). If the sink still flaps, check for real USB resets and disable autosuspend for `0db0:cd0e`.
