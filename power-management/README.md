# Power Management Configuration

This folder contains power management optimizations for maximum performance with sleep/hibernate disabled.

## Problem

The RTX 5090 does not properly recover from suspend/hibernate on Linux:
- PCIe link fails to renegotiate after resume (drops from Gen 4 to Gen 1)
- GPU clock limits are reset after resume
- Xid errors occur due to corrupted GPU state
- Only a full reboot restores proper functionality

Additionally, the ASMedia ASM4242 USB4/Thunderbolt controller (built into the MSI X870 motherboard) triggers spurious wake events, causing the system to wake immediately after entering suspend.

## Solution

Disable all sleep states and configure system for maximum performance:

1. **Disable suspend/hibernate** - Prevents broken GPU state after resume
2. **Disable USB4 wake** - Prevents spurious wake events
3. **Set Performance power profile** - Maximum CPU/GPU performance
4. **Screen blank only** - Screen blanks after 5 minutes, but system stays fully running

## Installed Files

| File | Destination | Purpose |
|------|-------------|---------|
| `disable-sleep.conf` | `/etc/systemd/sleep.conf.d/` | Disables all sleep states |
| `90-disable-usb4-wake.rules` | `/etc/udev/rules.d/` | Disables wake from USB4 controller |
| `system76-performance.service` | `/etc/systemd/system/` | Sets Performance profile at boot |

## Installation

### Quick install (recommended)

```bash
sudo ./install-power-management.sh
```

### Manual install

```bash
# Disable suspend/hibernate
sudo mkdir -p /etc/systemd/sleep.conf.d
sudo cp disable-sleep.conf /etc/systemd/sleep.conf.d/

# Disable USB4 wake
sudo cp 90-disable-usb4-wake.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

# Set System76 Performance profile to persist across reboots
sudo cp system76-performance.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now system76-performance.service

# Configure screen blank (5 min) without suspend
gsettings set org.gnome.desktop.session idle-delay 300
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

# Reboot to apply
sudo reboot
```

## Verification

After reboot:

```bash
# Check sleep is disabled
systemctl status sleep.target suspend.target hibernate.target

# Check power profile
system76-power profile
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Check USB4 wake is disabled
cat /sys/bus/pci/devices/0000:71:00.0/power/wakeup
```

## Rollback

### Quick rollback

```bash
sudo ./uninstall-power-management.sh
```

### Manual rollback

To re-enable sleep/hibernate:

```bash
sudo rm /etc/systemd/sleep.conf.d/disable-sleep.conf
sudo rm /etc/udev/rules.d/90-disable-usb4-wake.rules
sudo udevadm control --reload-rules
sudo reboot
```

## References

- [RTX 5090 PCIe Gen 1 after suspend - NVIDIA Forums](https://forums.developer.nvidia.com/t/multi-display-on-rtx-5090-on-fedora-not-working-graphics-stuck-in-gen1/337189)
- [system76-power profiles](https://github.com/pop-os/system76-power)
- [ASMedia ASM4242 USB4 Controller](https://www.asmedia.com.tw/product/e20zx49yU0SZBUH5/363Zx80yu6sY3XH2)
