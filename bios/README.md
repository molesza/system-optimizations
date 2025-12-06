# BIOS Configuration

MSI MAG X870 TOMAHAWK WIFI BIOS settings profiles.

## Files

| File | Description | Date |
|------|-------------|------|
| `MsiProfile.ocb` | Stable profile with RTX 5090 fixes | 2025-12-06 |

## Key Settings Changed

Settings modified from defaults to resolve RTX 5090 stability issues:

- **Spectrum Stream**: Disabled (was causing issues with PCIe communication)
- Other BIOS-level adjustments as needed for Blackwell GPU compatibility

## How to Restore

1. Copy `MsiProfile.ocb` to a FAT32-formatted USB drive
2. Boot into BIOS (press DEL during POST)
3. Navigate to OC Profile section
4. Load profile from USB

## Hardware Context

- **Motherboard**: MSI MAG X870 TOMAHAWK WIFI
- **BIOS Version**: E7E51AMS.1A6 (or later)
- **CPU**: AMD Ryzen 7 9800X3D
- **GPU**: NVIDIA GeForce RTX 5090
