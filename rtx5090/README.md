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
sudo cp systemd/nvidia-powerd-fix.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable nvidia-powerd-fix.service
```

Or use the install script:

```bash
./scripts/install-nvidia-fix.sh
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
| `systemd/nvidia-powerd-fix.service` | Systemd unit to apply fixes at boot |
| `scripts/install-nvidia-fix.sh` | Installation script |

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

## Changelog

- **2025-12-06**: Initial fix implemented - clock limits + persistence mode
