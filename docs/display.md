# XN254 display bring-up

The internal XN254 display path is the current project boundary. The hardware
stack is present in the selected source, but no native frame has been confirmed
on the physical panel after handoff.

## Verified on hardware

- The patched mainline kernel reaches a RAM-only initramfs.
- USB ACM provides a working diagnostic console.
- The DRM/MSM stack creates a framebuffer and DRM card.
- The XN254 and MSM modules bind during the diagnostic takeover.
- XN254 DCS status reads `0x0a=0x9c` and `0x0e=0x80` in the sampled state.
- DPU LM CRCs distinguish native blue, red, and repeated blue frames.
- DPU INTF CRCs distinguish the same A/B/A sequence.
- PP_DONE, CTL_START, and TE read pointers continue to advance.
- The firmware splash is visible until native takeover, then the panel becomes
  black.
- EXP-053 removed the earlier SMMU context faults, DSI FIFO errors, DSI PLL
  unlock reports, and vblank timeouts from the capture window.
- EXP-054 reissued the default brightness after the first native frame. The panel
  remained black.

The LM/INTF result is the strongest positive native-display signal. It proves
that distinguishable source data reaches the DPU interface sampling point. It
does not prove DSI transport, XN254 reception, DSC decode, or illumination.

## Excluded by controlled experiments

| Hypothesis | Experiments | Current conclusion |
|---|---|---|
| Restoring the MDSS core reset by itself produces visible output | EXP-037, EXP-041, EXP-053 | No. The reset path changed error behavior but did not bring the panel up. |
| The basic DSC packet-width calculation is the only fault | EXP-023, EXP-056 | No for the tested configuration. The rejected width variant is retained as a historical negative result. |
| Reissuing the default DCS brightness after first frame is sufficient | EXP-054 | No. The panel stayed black. |
| Holding all three panel enable GPIOs at firmware output levels is sufficient | EXP-047 | No. Splash can survive binding, but native output is still missing. |
| A generic Host1x or display-controller reset explains the entire failure | Multiple reset experiments | The generic explanation is too broad. Reset timing is one variable in a longer transport and panel-power path. |
| Command MISR was disabled when `0x130=0xffffffff` | Historical review | The earlier “no pixels reached DSI” conclusion is invalid because the MISR path was disabled. |

## Remaining boundary

```text
DPU INTF
  -> DSI command MDP0 and DSC packet generation
  -> DSI high-speed lanes and PHY
  -> XN254 receiver and DSC decode
  -> panel power, backlight, and final illumination
```

The source analysis found that OPPO and mainline calculate the same 840-byte DSC
slice chunk and 1681-word command packet for the tested mode. The command stream
uses packet type `0x39`, virtual channel 0, and one compressed packet per line in
the sampled attempt. Source agreement does not establish electrical delivery.

## EXP-057

EXP-057 enables the DSI0 command MISR path before the A/B/A frame sequence. The
module was built but has not run on hardware. Its expected decision is narrow:

- If command MISR follows the blue/red/blue pattern, continue below the command
  engine toward DSC packetization and lane/PHY transport.
- If command MISR remains unchanged while the enable bit is set, review enable
  timing, register mapping, command packet scheduling, and capture semantics
  before changing packet geometry.
- If the enable bit cannot be established, the measurement does not answer the
  transport question and must not be promoted to a negative proof.

The experiment must preserve the previously rejected packet-width path and test
only one behavioral variable.

## Power and brightness cautions

The tested data identify panel enable GPIO 6, TE GPIO 86, reset GPIO 146, PMIC
GPIO 4 for VDDR enable, and three supply rails. The vendor and mainline driver
models differ in reset polarity, continuous-splash ownership, brightness timing,
and power sequencing.

Do not change GPIO polarity, DSC parameters, PHY settings, and brightness together.
Do not disable protection rails or use an unverified high-current state to force a
visible result. Do not infer another hardware revision's rails from these values.

## Acceptance for visible display

A visible native frame is not enough to mark display support complete. Acceptance
requires a clean cold boot and repeatable evidence for:

1. XN254 firmware load and status
2. command stream and DSC delivery
3. native pixels visible on the panel
4. correct color and geometry
5. normal brightness control
6. blank and unblank lifecycle
7. suspend and resume where supported
8. recovery to the original software
