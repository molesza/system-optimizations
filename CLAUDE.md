# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Startup Tasks

**On each new session, run these commands to ensure documentation is current:**

```bash
# Update Pop!_OS official docs
cd ~/system-optimizations/pop-os-docs && git pull --ff-only

# Check for any new system issues since last session
journalctl -b | grep -iE "(xid|error|fail)" | grep -ivE "firefox" | tail -20
```

## Pending Verification (Next Session)

**After reboot, verify RTX 5090 fixes are working:**

```bash
# 1. Check boot service applied clocks
systemctl status nvidia-powerd-fix.service

# 2. Verify persistence mode is enabled
nvidia-smi -q | grep "Persistence Mode"

# 3. Check for any Xid errors this boot
journalctl -b | grep -i xid
```

If user tested Windows dual-boot, ask if Windows had any GPU issues on startup.

**Remove this section once verified.**

## Purpose

This repository contains system optimizations for Pop!_OS Linux. Scripts and configurations here modify system behavior for performance, power management, or user experience improvements.

## System Context

- **OS**: Pop!_OS 22.04 LTS (Ubuntu-based, uses systemd)
- **Kernel**: 6.17.4-76061704-generic (System76)
- **Package Manager**: apt (with Pop!_OS repos)
- **Init System**: systemd
- **Desktop**: COSMIC/GNOME

### Hardware Summary

| Component | Model |
|-----------|-------|
| **CPU** | AMD Ryzen 7 9800X3D (8C/16T, 96MB 3D V-Cache) |
| **GPU** | NVIDIA GeForce RTX 5090 32GB (requires `nvidia-driver-XXX-open`) |
| **RAM** | 64GB DDR5 |
| **Motherboard** | MSI MAG X870 TOMAHAWK WIFI |
| **Storage** | 1TB NVMe (Pop!_OS), 4TB NVMe (Windows), 128GB NVMe |
| **Monitors** | 3x DELL G3223Q (4K 144Hz DisplayPort) |
| **Network** | Realtek RTL8126A 5GbE, Qualcomm WCN7850 WiFi 7 |

See `HARDWARE.md` for complete hardware inventory.

## Repository Structure

```
system-optimizations/
├── CLAUDE.md           # This file - guidance for Claude Code
├── HARDWARE.md         # Complete hardware inventory
├── ISSUES.md           # Known issues and potential optimizations
├── pop-os-docs/        # Official Pop!_OS documentation (git submodule)
│   └── src/            # Documentation source files (mdBook format)
├── rtx5090/            # RTX 5090 specific fixes
│   ├── README.md       # Problem/solution documentation
│   ├── nvidia-powerd-fix.service
│   ├── install-nvidia-fix.sh
│   └── scripts/
│       └── nvidia-reset.shutdown  # Dual-boot GPU state reset
└── <component>/        # Future component-specific folders
```

## Pop!_OS Documentation Reference

The `pop-os-docs/` folder contains the official Pop!_OS documentation cloned from https://github.com/pop-os/docs.

### Key Documentation Locations

| Topic | Path |
|-------|------|
| Getting Started | `pop-os-docs/src/getting-started/` |
| Customize Pop!_OS | `pop-os-docs/src/customize-pop/` |
| Navigate Pop!_OS | `pop-os-docs/src/navigate-pop/` |
| Manage Apps | `pop-os-docs/src/manage-apps/` |
| Table of Contents | `pop-os-docs/src/SUMMARY.md` |

### Keeping Docs Updated

```bash
cd ~/system-optimizations/pop-os-docs
git pull --ff-only
```

The docs use mdBook format. To view locally: `mdbook serve` (requires `cargo install mdbook`).

### Organization Pattern

Each hardware component or subsystem gets its own folder containing:
- `README.md` - Problem description, root cause, solution, and references
- Service files, scripts, and configs specific to that component
- Install/uninstall scripts when applicable

## Current Optimizations

| Component | Issue | Fix | Status |
|-----------|-------|-----|--------|
| RTX 5090 | Xid 13/69 errors, driver resets | Clock limit (2407 MHz) + persistence mode | ✅ Fixed |

See `ISSUES.md` for pending issues and optimization opportunities.

## Common Operations

```bash
# Apply a systemd service
sudo cp <service>.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now <service>

# Apply sysctl tweaks
sudo cp <config>.conf /etc/sysctl.d/
sudo sysctl --system

# Apply udev rules
sudo cp <rule>.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Apply modprobe configuration
sudo cp <config>.conf /etc/modprobe.d/
sudo update-initramfs -u
```

## Diagnostic Commands

```bash
# System logs for current boot
journalctl -b

# NVIDIA GPU status and errors
nvidia-smi
journalctl -b | grep -iE "(nvidia|nvrm|xid)"
nvidia-smi -q | grep -iE "(clock|power|persistence)"

# CPU frequency and governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference

# System76 power profile
system76-power profile

# Check failed services
systemctl --failed

# Boot time analysis
systemd-analyze blame

# Hardware info
lspci -vnn
lsusb
```

## Key System Notes

### Kernel Boot Parameters
The system uses aggressive performance tuning:
- `mitigations=off` - CPU security mitigations disabled
- `idle=poll` - CPU never enters idle (high power, low latency)
- `threadirqs` - Threaded interrupt handlers
- `nowatchdog` - Watchdog disabled

### NVIDIA Driver
- RTX 5000 series requires the **open kernel module** (`nvidia-driver-XXX-open`)
- The proprietary driver does not support Blackwell architecture
- Pop!_OS packages the correct driver automatically

### Power Management
- **CPU Driver**: amd-pstate-epp (active mode)
- **System76 Power**: Balanced/Performance/Battery profiles available
- **ZRAM**: 31GB compressed swap configured

## Safety Guidelines

- Always backup original system files before replacing
- Test changes in isolation before combining multiple optimizations
- Include rollback instructions in scripts that modify system state
- Prefer drop-in configurations over modifying system defaults
- Document the problem, root cause, and solution in each component's README.md
- Reference external sources (forums, documentation) when applicable

## Important Notes for Claude Code

- **User must run sudo commands**: Claude Code cannot execute sudo commands directly. When system modifications are needed (copying files to /etc, /lib, enabling services, etc.), provide the commands for the user to run manually or ask them to approve the execution.
- Most optimizations in this repo require root privileges to install.
