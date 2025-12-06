# NVIDIA RTX 5090 Stability Fixes

## System Information

- **GPU**: NVIDIA GeForce RTX 5090 (Palit, 32GB GDDR7)
- **Driver**: nvidia-driver-580-open (580.82.09) - Open kernel module
- **OS**: Pop!_OS 22.04 LTS
- **Kernel**: 6.17.4-76061704-generic (System76)
- **Monitors**: 3x DELL G3223Q (4K DisplayPort)

## Problem Description

After boot, the system experienced:
- Sluggish desktop performance
- Periodic screen freezes/stutters
- NVIDIA driver recovery cycles (visible as brief display glitches)

### Root Cause

The NVIDIA driver was allowing GPU clocks up to **3090 MHz**, exceeding the RTX 5090's stable operating range (~2407 MHz boost clock). This caused:

- **Xid 13**: Graphics Exception - Illegal instruction encoding
- **Xid 69**: Class Error - Channel timeout and mismatch errors

Example errors from `journalctl`:
```
NVRM: Xid (PCI:0000:01:00): 13, Graphics Exception: ESR 0x4041b0=0xffff
NVRM: Xid (PCI:0000:01:00): 69, pid=3728, name=Xorg, Class Error: channel 0x00000003
NVIDIA(0): The NVIDIA X driver has encountered an error; attempting to recover...
NVIDIA: Wait for channel idle timed out.
```

## Solution

### 1. Limit GPU Clocks to Manufacturer Specification

```bash
sudo nvidia-smi -lgc 180,2407
```

This limits the GPU to 180-2407 MHz, preventing unstable overclocking.

### 2. Enable Persistence Mode

```bash
sudo nvidia-smi -pm 1
```

Keeps the GPU driver loaded and initialized, preventing state resets.

### 3. Make Changes Permanent (systemd service)

Install the systemd service to apply fixes at boot:

```bash
sudo cp nvidia-powerd-fix.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable nvidia-powerd-fix.service
```

### 4. Dual-Boot Compatibility (shutdown script)

For dual-boot systems (e.g., with Windows), install the shutdown script to reset GPU state:

```bash
sudo cp scripts/nvidia-reset.shutdown /lib/systemd/system-shutdown/
sudo chmod +x /lib/systemd/system-shutdown/nvidia-reset.shutdown
```

This script runs during shutdown and:
- Resets GPU clocks to default (`nvidia-smi -rgc`)
- Disables persistence mode (`nvidia-smi -pm 0`)

This ensures Windows boots with a clean GPU state.

### Quick Install

Use the install script to set up everything:

```bash
./install-nvidia-fix.sh
```

## Verification

Check that fixes are applied:

```bash
# Check persistence mode
nvidia-smi -q | grep "Persistence Mode"
# Should show: Persistence Mode : Enabled

# Check clock limits
nvidia-smi -q -d CLOCK | grep -A2 "Clocks Policy"
# Should show locked clocks

# Monitor for Xid errors
journalctl -f | grep -i xid
# Should be silent
```

## Files

| File | Purpose |
|------|---------|
| `nvidia-powerd-fix.service` | Systemd unit to apply fixes at boot |
| `scripts/nvidia-reset.shutdown` | Shutdown script to reset GPU state for dual-boot |
| `install-nvidia-fix.sh` | Installation script |

## References

- [NVIDIA Forums: RTX 5090 Hard Crashes - Clock Fix](https://forums.developer.nvidia.com/t/5090-hard-crashes/342157)
- [NVIDIA Forums: RTX 5090 Xid 13 Errors](https://forums.developer.nvidia.com/t/rtx-5090-xid-13-illegal-instruction-encoding-with-nvidia-driver-580-open-on-ubuntu-24-04/349791)
- [NVIDIA Xid Error Documentation](https://docs.nvidia.com/deploy/xid-errors/)
- [Level1Techs: Linux RTX 5090 Launch Guide](https://forum.level1techs.com/t/linux-rtx-5090-and-5080-launnch-kernel-upgrade-better-perf-install-drivers/225116)

## Notes

- RTX 5000 series **requires** the open kernel module (`nvidia-driver-XXX-open`)
- The proprietary driver does not support Blackwell architecture
- Pop!_OS packages the correct driver via `nvidia-driver-580-open`
- This is a known issue affecting some RTX 5090 cards; NVIDIA may fix this in future driver updates

## Known Issue: PCIe Link Speed Degradation

### Symptoms

After boot, the GPU may operate at PCIe Gen1 (2.5 GT/s) instead of Gen4 (16 GT/s), causing:
- Mouse lag and stuttering
- Window movement jerkiness
- General desktop sluggishness
- ~12x reduction in PCIe bandwidth

### Diagnosis

```bash
# Check current PCIe link speed
cat /sys/bus/pci/devices/0000:01:00.0/current_link_speed
# Should be "16.0 GT/s PCIe" for Gen4, NOT "2.5 GT/s PCIe"

# Check max supported speed
cat /sys/bus/pci/devices/0000:01:00.0/max_link_speed

# Detailed PCIe link status (requires sudo)
sudo lspci -vvv -s 01:00.0 | grep -iE "(lnksta|lnkcap)"
# LnkSta should show "Speed 16GT/s" not "Speed 2.5GT/s (downgraded)"

# Check kernel boot messages for PCIe warnings
journalctl -b | grep -i "pcie.*limited"
```

### Root Cause

This is a known issue with RTX 5090 + AMD X870 motherboards:
- PCIe 5.0 signal integrity issues cause link training failures
- The GPU falls back to Gen1 as a safe mode
- Affects 15-25% of RTX 5090 installations

### BIOS Settings (MSI MAG X870 TOMAHAWK WIFI)

Verify these settings in BIOS:
1. **PCIe Slot Speed**: Set to **Gen4** (not Auto or Gen5)
2. **ASPM (Active State Power Management)**: **Disabled** for GPU slot
3. **Above 4G Decoding**: **Enabled**
4. **Re-Size BAR Support**: **Enabled**

### Workarounds

1. **Cold boot**: Full shutdown (not restart), wait 30 seconds, power on
2. **BIOS update**: Check for latest MSI BIOS with AGESA updates
3. **VBIOS update**: See VBIOS Update Procedure below

---

## VBIOS Update Procedure

### Current VBIOS Information

| Property | Value |
|----------|-------|
| GPU | Palit GeForce RTX 5090 GameRock |
| Current VBIOS | 98.02.2E.40.61 |
| Available VBIOS | 98.02.2E.80.10 (April 2025) |
| Source | [TechPowerUp VBIOS Database](https://www.techpowerup.com/vgabios/?model=RTX+5090) |

### Prerequisites

- USB drive formatted as FAT32
- NVFlash 5.867 or later ([download](https://www.techpowerup.com/download/nvidia-nvflash/))
- Backup of current VBIOS
- **Warning**: Your Ryzen 9800X3D has no integrated graphics - if flash fails, you have no display fallback

### Step 1: Download Tools and VBIOS

```bash
# Create working directory
mkdir -p ~/vbios-update && cd ~/vbios-update

# Download NVFlash (get latest from TechPowerUp)
# Extract to this directory
```

Download the VBIOS file (98.02.2E.80.10) from TechPowerUp for "Palit RTX 5090 GameRock"

### Step 2: Backup Current VBIOS

```bash
cd ~/vbios-update

# Backup current VBIOS (CRITICAL - do this first!)
sudo ./nvflash --save backup-98.02.2E.40.61.rom

# Verify backup was created
ls -la backup*.rom
```

**Keep this backup safe** - you'll need it if the new VBIOS causes issues.

### Step 3: Flash New VBIOS

```bash
# Flash the new VBIOS
sudo ./nvflash new-vbios.rom

# Follow prompts - type 'y' to confirm when asked
# DO NOT interrupt the process or power off
```

### Step 4: Reboot and Verify

```bash
# Reboot system
sudo reboot

# After reboot, verify new VBIOS version
nvidia-smi -q | grep "VBIOS"
# Should show: 98.02.2E.80.10

# Check PCIe link speed
cat /sys/bus/pci/devices/0000:01:00.0/current_link_speed
```

### Rollback Procedure

If the new VBIOS causes issues:

```bash
cd ~/vbios-update
sudo ./nvflash backup-98.02.2E.40.61.rom
sudo reboot
```

### References

- [NVFlash Guide](https://www.techpowerup.com/download/nvidia-nvflash/)
- [TechPowerUp VBIOS Database](https://www.techpowerup.com/vgabios/?model=RTX+5090)
- [RTX 5090 PCIe Issues](https://www.ofzenandcomputing.com/rtx-5090-fe-pcie-5-0-compatibility-issues-reported-owners-find-workaround-force-pcie-4-0-mode/)

---

## Changelog

- **2025-12-06**: Added PCIe link speed degradation diagnosis and VBIOS update procedure
- **2025-12-06**: Added shutdown script for dual-boot GPU state reset
- **2025-12-06**: Initial fix implemented - clock limits + persistence mode
