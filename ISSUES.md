# Known Issues and Potential Optimizations

Last updated: 2025-12-14

## Active Issues

### 1. RTX 5090 Xid Errors (FIXED)
- **Status**: ✅ Fixed
- **Folder**: `rtx5090/`
- **Problem**: Xid 13/69 errors causing sluggishness and driver recovery cycles
- **Cause**: Driver allowing clocks up to 3090 MHz, exceeding stable silicon limits
- **Solution**: Clock limit to 2407 MHz + persistence mode
- **Install**: `./rtx5090/install-nvidia-fix.sh`

### 2. Sleep/Suspend Breaks GPU (FIXED)
- **Status**: ✅ Fixed
- **Folder**: `power-management/`
- **Problem**: After suspend/resume, GPU is in broken state:
  - PCIe link drops from Gen 4 to Gen 1 (2.5 GT/s instead of 16 GT/s)
  - GPU clock limits are reset (3090 MHz instead of 2407 MHz)
  - Xid 32 errors occur due to corrupted GPU state
  - Only a full reboot restores proper functionality
- **Additional issue**: ASMedia ASM4242 USB4/Thunderbolt controller triggers spurious wake events
- **Cause**: RTX 5090 Linux driver doesn't properly reinitialize PCIe link after S3 suspend
- **Solution**: Disable all sleep states, disable USB4 wake, use screen blank only
- **Install**: See `power-management/README.md`

### 3. CPU Governor Powersave (FIXED)
- **Status**: ✅ Fixed
- **Problem**: System was using `powersave` governor despite having `idle=poll` in kernel params
- **Solution**: Set System76 Power profile to Performance
- **Command**: `sudo system76-power profile performance`

### 4. Audio Sink Flapping / GNOME Volume Errors (FIXED)
- **Status**: ✅ Fixed
- **Folder**: `audio/`
- **Problem**: PipeWire/WirePlumber repeatedly recreated the onboard USB audio device, causing GNOME volume UI assertion failures and audio/video instability
- **Investigation date**: 2025-12-14

#### Investigation Findings

1. **NVIDIA HDMI audio was previously blacklisted incorrectly**:
   - `/etc/modprobe.d/blacklist-nvidia-hdmi.conf` contained `blacklist snd_hda_intel`
   - This disabled ALL HDA audio, including what was thought to be onboard Realtek
   - Fixed by replacing with targeted HDMI codec block: `install snd_hda_codec_hdmi /bin/true`

2. **X870 TOMAHAWK uses USB-based audio (ALC4080), not HD Audio**:
   - The AMD HD Audio Controller (73:00.6) shows "no codecs found" - this is expected
   - The motherboard routes audio through USB: `0db0:cd0e` (Realtek ALC4080)
   - This is MSI's "Audio Boost 5" design for better audio isolation

3. **Fifine USB microphone registers as keyboard**:
   - Device `0c76:161e` (JMTek USB PnP Audio) has HID interface for volume knob
   - May send spurious volume control events
   - Can be disabled via X11 InputClass if problematic:
     ```
     Section "InputClass"
         Identifier "Ignore JMTek USB PnP Audio HID"
         MatchProduct "USB PnP Audio Device"
         Option "Ignore" "on"
     EndSection
     ```

4. **RTL8127A firmware warning resolved**:
   - `update-initramfs` warned about missing `rtl8127a-1.fw`
   - Downloaded from upstream linux-firmware to `/lib/firmware/rtl_nic/`
   - Note: RTL8127A is 10GbE chip (not present), warning was spurious

#### Configuration Files
- `/etc/modprobe.d/blacklist-nvidia-hdmi.conf` - Blocks NVIDIA HDMI audio codec
- `/etc/modprobe.d/alsa-realtek-fix.conf` - Can be removed (probe_mask not needed)

#### Fix Applied

- Add MSI X870 Tomahawk USB ID (`0db0:cd0e`) to the `alsa-ucm-conf` `If.realtek-alc4080` match and persist it with `dpkg-divert`.
- **Install**: `sudo ./audio/install-alc4080-ucm-fix.sh --divert`
- **Rollback**: `sudo ./audio/uninstall-alc4080-ucm-fix.sh`

#### References
- [ALC4080 support issue - GitHub](https://github.com/alsa-project/alsa-ucm-conf/issues/455)
- [MSI X870 TOMAHAWK specs - KitGuru](https://www.kitguru.net/components/motherboard/leo-waldock/msi-mag-x870-tomahawk-review/)

---

## Potential Issues to Investigate

### 2. Firefox WebRender Graphics Glitches
- **Status**: 👀 Monitoring
- **Observed**: 2025-12-06 - Graphics artifacts in Firefox window after GPU Xid recovery events
- **Symptoms**: Visual corruption/glitches in Firefox rendering
- **Context**: Occurred after GPU driver recovery from Xid errors (before clock fix was applied)
- **Resolution**: Restarting Firefox cleared the issue
- **Root cause**: Likely stale GPU state in Firefox's WebRender compositor after driver recovery
- **If issue recurs**:
  - Restart Firefox to clear GPU state
  - Check `about:support` → "Compositing" should show "WebRender"
  - Temporary workaround: `about:config` → `gfx.webrender.force-disabled` = `true` (disables GPU rendering)
- **Related**: RTX 5090 Xid errors (Issue #1) - may reoccur if GPU becomes unstable

### 3. Razer Cobra Mouse Event Lag
- **Status**: 🔍 Needs investigation
- **Symptoms**:
  ```
  event7 - Razer Razer Cobra: client bug: event processing lagging behind by 23ms
  event7 - Razer Razer Cobra: SYN_DROPPED event - some input events have been lost
  ```
- **Frequency**: Multiple times per boot, especially during GPU recovery events
- **Possible causes**:
  - High polling rate (1000Hz+) combined with GPU driver issues
  - USB hub latency
  - Input event queue overflow during system load
- **Potential fixes**:
  - Check if using USB 2.0 or 3.0 port
  - Lower polling rate temporarily to test
  - Install openrazer for better driver support

### 5. NetworkManager-wait-online.service Failed
- **Status**: ⚠️ Minor
- **Impact**: Adds 5s to boot time, then fails
- **Cause**: Service times out waiting for network to be fully online
- **Potential fix**: Disable if not needed: `sudo systemctl disable NetworkManager-wait-online.service`

### 6. WiFi Soft Blocked
- **Status**: ℹ️ Informational
- **Current**: WiFi (wlp8s0) is soft-blocked via rfkill
- **Impact**: None if using ethernet intentionally
- **Note**: Qualcomm WCN7850 (WiFi 7) with ath12k driver is functional if needed

### 7. Long Firmware Boot Time
- **Status**: ⚠️ BIOS/UEFI
- **Current**: 24.8s firmware + 3.7s loader = 28.5s before kernel
- **Total boot**: 51.5s to graphical target
- **Potential fixes**:
  - Check BIOS for "Fast Boot" option
  - Disable unused boot devices
  - Update BIOS if newer version available

### 8. Ethernet Running at 1Gbps (Hardware supports 5GbE)
- **Status**: ℹ️ Informational
- **Hardware**: Realtek RTL8126A supports 5 Gigabit
- **Current**: Link at 1Gbps
- **Possible causes**:
  - Cat5e cable (need Cat6a for 5GbE)
  - Switch/router doesn't support 5GbE
  - Auto-negotiation issue
- **Check**: Verify cable and switch capabilities

---

## Configuration Notes

### Kernel Parameters Analysis
| Parameter | Purpose | Trade-off |
|-----------|---------|-----------|
| `mitigations=off` | Disables Spectre/Meltdown fixes | +5-10% performance, reduced security |
| `nowatchdog` | Disables hardware watchdog | Slightly lower power, no auto-reboot on hang |
| `threadirqs` | Threaded interrupt handlers | Better latency distribution |
| `idle=poll` | CPU never enters idle states | Lowest latency, highest power consumption |

**Note**: `idle=poll` is aggressive - CPU cores never sleep. This is typically used for ultra-low-latency workloads (audio production, real-time systems). For gaming, `idle=nomwait` or removing it entirely may be more appropriate.

### System76 Power Profile
- **Current**: Performance
- **Available**: Battery, Balanced, Performance
- **Note**: Set to Performance permanently for this desktop system

---

## Future Optimization Ideas

1. **Create performance profile script** - Toggle between gaming/productivity modes
2. **ZRAM tuning** - Current 31GB may be oversized for 64GB RAM
3. **I/O scheduler** - Check if NVMe drives using optimal scheduler
4. **GPU fan curve** - Custom fan curve for quieter operation
5. **Gamemode integration** - Auto-apply optimizations when gaming

---

## Potential Optimizations to Investigate

### 9. AMD Ryzen 9800X3D PBO Tuning
- **Status**: 🔍 Optional investigation
- **Current BIOS settings**:
  - PBO: Disabled
  - Gaming Mode: Disabled
- **Current performance**: CPU hitting 5.25 GHz (above rated 5.2 GHz boost) - working well
- **Why current settings are OK**:
  - Unlike other Ryzen 9000 CPUs, 9800X3D isn't power-limited at stock
  - PBO provides less benefit on this chip than others
  - Gaming Mode only useful for dual-CCD chips (9950X3D), not single-CCD 9800X3D
- **Potential gains with PBO**:
  - Could reach 5.3-5.4 GHz with proper tuning
  - Estimated 3-5% improvement in some workloads
- **Recommended PBO settings if enabling**:
  ```
  PBO: Enabled (or Advanced)
  Boost Override: +200 MHz
  Curve Optimizer: All Core, Negative, -20 (conservative start)
  Scalar: x10
  ```
- **Stability testing required**:
  - y-cruncher for AVX stability
  - Prime95 small FFTs for thermal testing
  - Game testing for real-world stability
- **Warnings**:
  - Some ASRock boards shipped with aggressive voltage settings - check voltage stays under 1.35V
  - Not all chips can handle -30 curve; start at -20
  - Requires adequate cooling (240mm AIO recommended for PBO)
- **References**:
  - [TechPowerUp 9800X3D Review](https://www.techpowerup.com/review/amd-ryzen-7-9800x3d/26.html)
  - [SkatterBencher 9800X3D Overclocking](https://skatterbencher.com/2024/11/06/skatterbencher-82-ryzen-7-9800x3d-overclocked-to-5750-mhz/)
  - [MSI X3D Gaming Mode](https://www.msi.com/blog/msi-x3d-gaming-mode-enhance-gaming-performance-on-amd-ryzen-processors)

### 10. RTX 5090 Undervolting and Power Optimization
- **Status**: 🔍 To investigate
- **Current state**:
  - Idle power: ~62W (with 3x 4K 144Hz monitors)
  - Power limit: 575W (stock)
  - Clock limit: 2407 MHz (our stability fix)
  - Coolbits: Not configured
- **Expected idle power**: 45-50W with dual 4K monitors, 5-6W headless
- **Current idle slightly high**: 62W may be normal for 3x 4K 144Hz, but could potentially be reduced

#### Undervolting Benefits
- **Reduced power consumption**: 70-170W less under load (16% savings)
- **Lower temperatures**: Significant temp reduction
- **Maintain performance**: 99% of stock performance possible
- **Quieter operation**: Lower temps = lower fan speeds

#### Undervolting Methods on Linux

**Method 1: LACT (Recommended)**
- GUI tool for NVIDIA/AMD GPU control
- Supports voltage curve, power limit, fan control
- Install: Available in some distro repos or from GitHub
- May require suspend/resume trick for settings to apply cleanly:
  ```bash
  echo suspend | sudo tee /proc/driver/nvidia/suspend
  echo resume | sudo tee /proc/driver/nvidia/suspend
  ```

**Method 2: nvidia-settings + Coolbits**
- Enable Coolbits for overclocking controls:
  ```bash
  sudo nvidia-xconfig --cool-bits=28
  ```
- Coolbits 28 enables: overclocking (8) + overvoltage (16) + fan control (4)
- Then use nvidia-settings to set clock offsets
- Undervolting via "overclocking": increase clock offset while keeping power limit = same performance, less power

**Method 3: Power Limit Only (Simplest)**
- Just reduce power limit without touching voltage:
  ```bash
  sudo nvidia-smi -pl 500  # Reduce from 575W to 500W
  ```
- GPU will downclock when hitting limit but maintains stability
- Good starting point before full undervolting

#### Reported Working Settings for RTX 5090
| Setting | Value | Notes |
|---------|-------|-------|
| Voltage | 0.875-0.9V | Down from ~1.0V stock |
| Core clock | 2600-2900 MHz | With undervolt |
| VRAM offset | +2200 MHz | Memory overclock |
| Power limit | 450-500W | Down from 575W |

#### Compatibility Notes
- **Our clock limit (2407 MHz)**: Already limiting max clocks for stability
- **Undervolting interaction**: Should be compatible - we're limiting clocks, undervolt reduces voltage at those clocks
- **Testing required**: Need to verify stability with both clock limit and undervolt

#### Idle Power Optimization
- Multiple 4K monitors at high refresh rate increase idle power
- Lowering refresh rate when not gaming can reduce idle power
- Some users report idle power issues that require driver updates

#### References
- [Level1Techs: GPU Idle Power & Undervolt on Linux](https://forum.level1techs.com/t/some-gpu-5090-4090-3090-a600-idle-power-consumption-headless-on-linux-fedora-42-and-some-undervolt-overclock-info/237064)
- [NVIDIA Open GPU Modules: Undervolting Discussion](https://github.com/NVIDIA/open-gpu-kernel-modules/discussions/236)
- [ArchWiki: NVIDIA Tips and Tricks](https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks)
- [ASUS ROG: Undervolting RTX 5090](https://rog-forum.asus.com/t5/push-the-limits/power-meets-precision-undervolting-your-rog-astral-oc-rtx-5090/ba-p/1093066)
- [HardForum: RTX 5090 Undervolting](https://hardforum.com/threads/rtx-5090-undervolting-uv.2043276/)
