# Evidence model

The project uses four evidence classes and a separate list of corrected history. A statement is promoted only when the class is explicit.

## Direct device evidence

- The device reaches a RAM initramfs from the patched mainline kernel.
- The diagnostic initramfs creates a USB ACM console.
- DRM/MSM creates a framebuffer and card in the binding path.
- XN254 DCS status reads `0x0a=0x9c` and `0x0e=0x80` in the sampled state.
- DPU LM CRCs distinguish blue, red, and repeated blue frames.
- DPU INTF CRCs distinguish the same A/B/A sequence.
- Firmware splash pixels remain visible before native takeover and the internal panel becomes black after takeover.
- PP_DONE, CTL_START, and TE read pointers increase while no visible native frame appears.
- The tested closure writes `boot_b`, returns to Fastboot through the diagnostic initramfs, restores the original image, and verifies the partition hash.

## Controlled exclusions

| Assumption | Experiment | Result |
|---|---|---|
| Restoring the MDSS core reset alone fixes native display | EXP-053 | Excluded. The handoff still ends in black. |
| Resending the default DCS brightness after the first native frame fixes output | EXP-054 | Excluded. The panel remains black. |
| The basic DSC packet width is the primary fault | EXP-023 and EXP-056 | Excluded for the tested configuration. The calculated width matches the vendor source path. |
| A command MISR read of `0xffffffff` proved that pixels never reached DSI MDP0 | Historical interpretation | The measurement was taken while command MISR was disabled. The conclusion is invalid. |
| A generic Host1x controller reset is enough for display | EXP-037 and EXP-053 | The normal MDSS reset path was restored without fixing the visible path. |
| Holding all three panel enable GPIOs at the firmware output level is sufficient | EXP-047 | The splash frame can survive binding, yet native output remains black. |

## Source-analysis conclusions

- OPPO source and mainline calculate the same 840-byte DSC slice chunk and 1681-word command packet for the current mode.
- The command stream uses packet type `0x39`, virtual channel 0, and one compressed packet per line in the sampled attempt.
- The DSI controller includes the expected command-mode, four-lane, clock, and RGB101010 enable bits.
- The vendor path and mainline path use different driver designs around continuous splash, brightness timing, and power sequencing. The behavioral importance of each difference remains experimental.

Source agreement does not establish hardware delivery.

## Unverified hypotheses

- DSI command MDP0 receives the native frame stream.
- DSC packet generation is correct after the command engine.
- DSI lane and PHY electrical output reaches the panel.
- The XN254 receives and decodes the command stream.
- The panel illumination path is active after native takeover.
- A vendor-specific KTZ8869 or other brightness path is required by this hardware.
- Two-LM and two-DSC topology is required for visible output on the tested panel mode.

## Corrected or superseded conclusions

- Older notes that display controller state read zero in Android were taken while multiple engines were idle. They do not prove that the hardware was absent.
- An older statement that the diagnostic initramfs lacked a bootloader return path was later superseded by a tested RAM initramfs return binary.
- The historical `0x130=0xffffffff` conclusion is not evidence of a missing pixel stream because command MISR was disabled.

## Status promotion rule

A hardware feature becomes `Working` only when all of the following are true:

1. A clean cold boot reaches the feature through the normal entry point.
2. A user-visible or externally measurable result is captured.
3. The result repeats after a clean reboot.
4. The original software recovery path remains available.

A build, module load, node creation, counter increment, or register read does not satisfy this rule by itself.