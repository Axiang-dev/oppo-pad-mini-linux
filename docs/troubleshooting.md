# Troubleshooting

## The firmware splash becomes black after takeover

Current evidence places native test frames at or before DPU INTF. The remaining
boundary is DSI command, DSC packetization, lane/PHY output, XN254 reception, and
panel illumination.

Collect DSI command MISR, DSC-related state, lane status, PLL, FIFO, timeout, TE,
DPU completion, and SMMU data before changing parameters. Do not repeat the
rejected packet-width change as the next step. Do not combine brightness, GPIO,
PHY, and DSC changes.

## Native frames produce DPU CRCs but the panel remains black

A DPU CRC proves sampled SoC-side output. Run EXP-057 to inspect DSI command
MDP0. If the command MISR is disabled or unreadable, fix enable timing and the
sampling path before treating the value as a transport failure.

## DRM exists but no display pipeline is active

Check whether the panel and MSM modules bound, whether the mode was prepared and
enabled, whether the CRTC is active, and whether the atomic commit reached the
firmware handoff. A DRM card alone does not indicate a visible frame.

## USB ACM is absent

The tested initramfs configures a USB gadget. Check that device mode is available,
configfs mounted, UDC enumerated, the ACM function linked, and the UDC bound. Use
the physical-key Fastboot entry if no debug channel is available. Do not assume
that a black screen means the boot chain is dead.

## Kernel returns to Fastboot or the original software

Preserve the first timestamped log, the candidate hash, and the exact previous
firmware state. Check the built-in FDT memory handoff, Image/DTB placement, AVB
descriptor, module load failures, console setup, and early exception output. Do not
treat the stock system appearing after `fastboot boot` as proof that the custom
kernel executed successfully.

## Module load reports an unknown symbol or invalid module format

The kernel configuration, source revision, toolchain, architecture, vermagic, and
module set must match the Image. Rebuild all diagnostic modules with the same tree
and configuration. Do not mix modules from another kernel build.

## GPU cannot initialize

Confirm the Adreno catalog entry, GMU firmware file, power domains, interconnect,
SMMU streams, and GPU ID before changing render userspace. Do not describe
llvmpipe, software KMS painting, or a framebuffer copy as Adreno acceleration.

## The host cannot see standard Fastboot

Stop. Confirm the correct physical-key sequence and cable, then use the tested
recovery procedure. A device that failed a diagnostic boot is not safe to treat as
a generic Fastboot target until the endpoint is confirmed.

## The build fails on a newer kernel or config

The diagnostic patch applies to commit `6a876df4686788cd39128b62d7fcbff62f39278f`
only. Rebase deliberately into a new patch series and rerun DTB, Image, module,
packaging, privacy, and hardware validation. Do not silently apply fuzz or ignore
patch failures.
