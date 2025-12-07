# Known Issues and Potential Optimizations

Last updated: 2025-12-07

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

### 4. CPU Governor Set to Powersave (FIXED)
- **Status**: ✅ Fixed (see Issue #3)
- **Solution**: System76 Power profile set to Performance

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
