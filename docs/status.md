# Current status

Last evidence review: 2026-11-26.

## Summary

The mainline diagnostic kernel reaches a RAM-only initramfs on OPD2515 and exposes a USB ACM console. The DRM/MSM stack binds to the display controller, and DPU LM and INTF signatures distinguish test frames. The internal XN254 panel remains dark after the bootloader handoff.

The current failure boundary spans the path from the DPU interface through the DSI command engine and DSC stream, lane PHY transmission, panel reception, and the panel illumination path. EXP-057 was built to inspect the DSI command MDP0 signature. It has not run on hardware.

This project has no supported end-user image. The tested device was recovered to its original software after experiments.

## Support matrix

| Function | Status | Evidence and limitation |
|---|---|---|
| Bootloader | Working | Unlock, Fastboot enumeration, `boot_b` write, reboot, and restoration were exercised on the tested unit. |
| Linux kernel boot | Partial | The patched mainline kernel reaches a RAM initramfs and USB shell. A persistent distribution boot has not been validated. |
| CPU | Working | The diagnostic kernel reaches userspace on the target SoC. Stress and frequency policy are unverified. |
| Memory | Working | The target memory map supports the diagnostic boot. Long-running stress and suspend behavior are unverified. |
| UFS | Partial | Storage resources initialize in the diagnostic path. A supported root filesystem installation has not been validated. |
| Display | Broken | The firmware splash remains visible until native handoff, then the internal panel turns black. |
| DPU | Partial | LM and INTF CRCs distinguish blue, red, and repeated blue frames. The final visible path is not working. |
| MIPI DSI | Partial | The command controller is enabled with four lanes and produces plausible register state. Physical delivery to the panel is unproven. |
| DSC | Partial | Calculated packet width and command-stream fields match the vendor source path. Panel decode and visible output fail. |
| Touchscreen | WIP | Goodix GT9966 is identified in the vendor device tree. A mainline input stack has not been validated. |
| Adreno GPU | Blocked | The target GPU catalog and GMU firmware support are incomplete for the selected mainline baseline. |
| OpenGL | Blocked | Hardware acceleration is blocked by the GPU bring-up. |
| Vulkan | Blocked | Hardware acceleration is blocked by the GPU bring-up. |
| Wi-Fi | Not Tested | No mainline connectivity result exists for WCN7750. |
| Bluetooth | Not Tested | No mainline connectivity result exists for the target WCN7750 integration. |
| USB | Partial | Device-mode USB ACM is working. Host mode, power delivery, and gamepad behavior are unverified. |
| Audio | Not Tested | No end-to-end mainline playback or capture result exists. |
| Battery | Not Tested | No supported mainline battery reporting result exists. |
| Charging | Not Tested | Proprietary charging and protection stacks have not been replaced or validated. |
| Thermal management | Not Tested | No mainline thermal policy acceptance result exists. |
| Suspend and resume | Not Tested | No repeated suspend cycle has been validated. |
| Desktop environment | Blocked | Native display and GPU support are prerequisites. |
| Steam | Not Tested | No Linux userspace platform has reached a usable device state. |
| Gamescope | Not Tested | Native display and GPU support are prerequisites. |
| FEX | Not Tested | No usable Armada userspace has been validated. |
| Proton | Not Tested | No usable Armada userspace has been validated. |

## Current display boundary

The strongest positive data point is the DPU INTF CRC. It proves that distinguishable native test frames reach the DPU interface sampling point. It does not prove that DSI packets reach the panel, that the panel decodes the stream, or that the illumination path is active.

The current line of investigation is:

```text
DPU INTF
  -> DSI command MDP0 and DSC stream
  -> DSI lanes and PHY
  -> XN254 receiver and decoder
  -> panel illumination
```

## Immediate next step

Run EXP-057 from a non-flashing boot path and verify that DSI command MISR is enabled and readable. The result will determine whether the working search moves below DPU INTF or returns to the controller enable and capture path.

Do not repeat the rejected packet-width change from EXP-023. Do not change DSC, PHY, brightness, and GPIO behavior together.