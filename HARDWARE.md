# System Hardware Inventory

Last updated: 2025-12-06

## System Overview

| Component | Model |
|-----------|-------|
| **Motherboard** | MSI MAG X870 TOMAHAWK WIFI (MS-7E51) v1.0 |
| **BIOS** | v1.A67 (2025-08-05) |
| **CPU** | AMD Ryzen 7 9800X3D (8-core/16-thread, 96MB L3 3D V-Cache) |
| **GPU** | NVIDIA GeForce RTX 5090 32GB (Palit) |
| **RAM** | 64GB DDR5 |
| **OS** | Pop!_OS 22.04 LTS |
| **Kernel** | 6.17.4-76061704-generic (System76) |

## CPU Details

- **Model**: AMD Ryzen 7 9800X3D 8-Core Processor
- **Architecture**: Zen 5 (Granite Ridge)
- **Base/Boost Clock**: 603 MHz - 5271 MHz
- **Cache**: 384 KiB L1d, 256 KiB L1i, 8 MiB L2, 96 MiB L3 (3D V-Cache)
- **Features**: AVX-512, AMD-V virtualization
- **Driver**: amd-pstate-epp (active mode)
- **Current Governor**: powersave
- **EPP Setting**: balance_performance

## GPU Details

- **Model**: NVIDIA GeForce RTX 5090
- **VRAM**: 32GB GDDR7
- **PCIe**: x16 @ 8.0 GT/s (Gen4)
- **Driver**: nvidia-driver-580-open (580.82.09) - Open kernel module
- **Firmware**: Included with driver package
- **Displays**: 3x DELL G3223Q (4K 144Hz) via DisplayPort

## Storage

| Device | Model | Size | Mount | Notes |
|--------|-------|------|-------|-------|
| nvme0n1 | WD Blue SN5000 | 4TB | (Windows) | NTFS partitions |
| nvme1n1 | Patriot M.2 P300 | 128GB | (unused) | |
| nvme2n1 | Hikvision HS-SSD-E2000 | 1TB | / (root) | Pop!_OS system drive |

### Swap Configuration
- **zram0**: 31.2GB compressed RAM swap (priority 5)
- **cryptswap**: 4GB encrypted disk swap (priority -2)

## Memory

- **Total**: 64GB DDR5
- **Available**: ~55GB typical
- **Transparent Hugepages**: madvise (recommended for gaming)

## Network

### Ethernet
- **Controller**: Realtek RTL8126A (5GbE)
- **Interface**: enp9s0
- **Driver**: r8169
- **Status**: UP @ 1Gbps
- **Note**: Hardware supports 5GbE but connected at 1Gbps (check cable/switch)

### WiFi
- **Controller**: Qualcomm WCN7850 (WiFi 7)
- **Interface**: wlp8s0
- **Driver**: ath12k
- **Status**: DOWN (soft blocked via rfkill - using ethernet)
- **Firmware**: WLAN.HMT.1.0.c5-00481 (2023-12-06)

### Bluetooth
- **Controller**: Foxconn/Hon Hai (Qualcomm)
- **Interface**: hci0
- **Status**: Active, not blocked

## Peripherals

- **Mouse**: Razer Cobra
- **Keyboard**: USB Keyboard (China Resource Semico)
- **Webcam**: Logitech HD Pro Webcam C920
- **Audio**: MSI USB Audio, JMTek USB Audio
- **Other**: MSI Mystic Light RGB controller

## Kernel Boot Parameters

```
nvidia-drm.modeset=1    # NVIDIA DRM modesetting
mitigations=off         # CPU security mitigations disabled (performance)
nowatchdog              # Watchdog disabled
threadirqs              # Threaded IRQ handlers
idle=poll               # CPU idle polling (low latency, high power)
```
