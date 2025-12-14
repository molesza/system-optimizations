# Reinstall Runbook (Pop!_OS)

Use this checklist after a fresh Pop!_OS install to reapply the optimizations in this repo. These changes affect system behavior; take a snapshot (Timeshift) first.

## 0) Get the repo

```bash
git clone <repo-url> ~/system-optimizations
cd ~/system-optimizations
```

## 1) Audio (MSI X870 Tomahawk ALC4080: `0db0:cd0e`)

Preferred path is to upgrade `alsa-ucm-conf` and verify `cd0e` is present. Pop!_OS 22.04 may ship an older build, so this runbook applies the upstream match locally and persists it across updates.

```bash
sudo ./audio/install-alc4080-ucm-fix.sh --divert
grep -n cd0e /usr/share/alsa/ucm2/USB-Audio/USB-Audio.conf
systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service
```

Stability check:

```bash
for i in {1..15}; do pactl list sinks short | grep -i usb | awk '{print $1,$2}'; sleep 2; done
```

Rollback: `sudo ./audio/uninstall-alc4080-ucm-fix.sh`

## 2) RTX 5090 stability (clock limit + persistence)

```bash
./rtx5090/install-nvidia-fix.sh
```

Verify:

```bash
nvidia-smi --query-gpu=clocks.max.graphics --format=csv,noheader
journalctl -b | grep -iE "xid" | tail -5
```

## 3) Power management (disable sleep + persist Performance profile)

```bash
sudo ./power-management/install-power-management.sh
```

Then (as your desktop user), configure “screen blank only” as desired (see `power-management/README.md`).

Verify:

```bash
systemctl status sleep.target suspend.target hibernate.target
system76-power profile
```

---

If anything behaves oddly after applying a fix, prefer rolling back that one component first (each folder documents rollback).
