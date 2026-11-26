# Experiment index

The raw local evidence archive contains serial captures, test scripts, build logs,
photographs, original partition images, and firmware. Those files are intentionally
excluded from Git because they can contain device identifiers, proprietary data,
or large build products.

This public index records decisions and durable conclusions. Local records remain
the source for detailed timing and raw output.

## Evidence classes

Every statement must identify one of these classes:

1. Direct device evidence
2. Controlled exclusion
3. Source-analysis conclusion
4. Unverified hypothesis
5. Corrected or superseded historical conclusion

See [evidence.md](evidence.md) for the current classification.

## Experiment history

| Range | Main question | Durable result |
|---|---|---|
| EXP-001 to EXP-016 | Can a vendor-GKI graft or minimal probe produce early boot evidence on the tested unit? | Several packaging and graft paths failed before reliable runtime evidence. These results motivated moving to a fixed mainline diagnostic tree instead of treating binary compatibility alone as success. |
| EXP-018 | Can a minimal RAM probe reach userspace and return to the bootloader? | The RAM probe established a repeatable early userspace and recovery-oriented test path. |
| EXP-019 | Can a mainline diagnostic display tree reach DRM/MSM and produce useful register evidence? | The diagnostic baseline became the reference tree for later display experiments. |
| EXP-020 to EXP-025 | Is the visible failure explained by panel callbacks, a single DSC packet-width field, or a stock PPS byte? | No single tested field or callback brought up output. EXP-023 is retained as a rejected packet-width experiment. |
| EXP-026 to EXP-036 | Do display clock ownership, GDSC, MDP, and VSYNC preservation fix the handoff? | Component clocks and splash-hold paths were observable, but the visible failure remained. These results separated resource preservation from final DSI/panel delivery. |
| EXP-037 to EXP-045 | Is controller reset, runtime suspend, or a generic MSM bind sequence the root cause? | The normal MDSS reset and runtime state changed error output, but no native frame reached the panel. |
| EXP-046 to EXP-050 | Is module binding or a specific panel-enable GPIO destroying the splash? | Module binding and panel-enable polarity matter. Holding all firmware GPIO levels is insufficient for native output. |
| EXP-051 to EXP-053 | Does preserving the panel while allowing a full native modeset plus MDSS reset expose the next boundary? | The native path reached atomic commit and generated frames. EXP-053 removed the prior SMMU, DSI FIFO, PLL, and vblank reports without visible display. |
| EXP-054 | Is default brightness missing after first native frame? | Reissuing the default brightness did not illuminate the panel. |
| EXP-055 | Do native test colors reach DPU interface sampling? | LM and INTF CRCs distinguish blue, red, and repeated blue. The search moved to DSI command, DSC, lanes, PHY, and XN254. |
| EXP-056 | Does source analysis confirm the compressed command packet geometry? | OPPO and mainline calculate the tested DSC slice and packet dimensions identically. Packet geometry is not the current primary fault. |
| EXP-057 | Does the DSI command MDP0 MISR sample the native frame stream? | Prepared and built. Hardware result pending. |

## Key tested closure

EXP-053 and subsequent no-flash reruns established a closure:

1. Boot the diagnostic Image.
2. Reach the RAM-only initramfs and USB ACM shell.
3. Load the native display modules without touching userdata.
4. Submit native blue, red, and blue frames.
5. Collect DPU, DSI, IRQ, and error evidence.
6. Request standard Fastboot through the diagnostic helper.
7. Restore the original boot image and verify recovery.

The closure does not imply that the boot partition is safe to write on another
unit or without a new owner authorization.

## Current next experiment

EXP-057 is the only current display next step:

- enable DSI0 command MISR while command mode is active
- sample the control/enable state
- drive A/B/A native frames
- read the command MDP0 signature at each phase
- correlate with LM and INTF CRCs and the complete DSI error log
- return to standard Fastboot without a new partition write

Do not repeat EXP-023 packet-width change as the next variable. Do not combine
DSI MISR with DSC, PHY, GPIO, or brightness changes.
