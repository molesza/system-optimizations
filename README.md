# System Optimizations for Pop!_OS

Personal system optimizations and fixes for my Pop!_OS Linux workstation.

## System Specs

| Component | Model |
|-----------|-------|
| CPU | AMD Ryzen 7 9800X3D (8C/16T, 96MB 3D V-Cache) |
| GPU | NVIDIA GeForce RTX 5090 32GB |
| RAM | 64GB DDR5 |
| Motherboard | MSI MAG X870 TOMAHAWK WIFI |
| OS | Pop!_OS 22.04 LTS |

## Current Fixes

### RTX 5090 Stability Fix

Fixes Xid 13/69 errors caused by the driver allowing GPU clocks beyond stable limits.

```bash
# Install (applies on every boot)
./rtx5090/install-nvidia-fix.sh
```

**What it does:**
- Limits GPU clocks to 180-2407 MHz (manufacturer spec)
- Enables persistence mode to prevent GPU state resets

See [rtx5090/README.md](rtx5090/README.md) for full details.

## Documentation

| File | Description |
|------|-------------|
| [HARDWARE.md](HARDWARE.md) | Complete hardware inventory |
| [ISSUES.md](ISSUES.md) | Known issues and potential optimizations |
| [CLAUDE.md](CLAUDE.md) | Guidance for Claude Code AI assistant |

## Reference

- `pop-os-docs/` - Official Pop!_OS documentation (cloned from [pop-os/docs](https://github.com/pop-os/docs))

## License

Personal configuration files. Use at your own risk.
