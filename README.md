# OPPO Pad Mini Linux Port

**OPD2515 / SM8845P / Molokai native ARM64 Linux bring-up**

English | [简体中文](README.zh-CN.md)

This is an unofficial community research project. It is not affiliated with,
endorsed by, or supported by OPPO, Qualcomm, Armada OS, ROCKNIX, or any other
upstream project named here.

## Project overview

This repository preserves the reproducible source and evidence boundary of an
OPPO Pad Mini OPD2515 port to native ARM64 Linux. It contains a diagnostic
mainline kernel patch, the tested kernel configuration, display bring-up
instruments, build tooling, and a hardware status matrix.

The project is in early development. There is no supported installer, end-user
image, or production-ready Linux distribution for OPD2515. A compiled kernel or
an enumerated DRM device does not establish that the internal display, GPU,
touchscreen, wireless, audio, or power-management paths work.

The current diagnostic kernel reaches a RAM-only initramfs and exposes a USB ACM
console. The firmware splash is visible before native takeover. Native DPU
frame signatures differ for blue and red test frames, but the internal XN254
panel becomes black after takeover. EXP-057 was prepared to inspect the DSI
command engine and has not run on hardware.

## Supported devices

| Device | Status | Tested software | Notes |
|---|---|---|---|
| OPPO Pad Mini OPD2515 | Experimental | ColorOS 16, build 16.0.10.500 CN01 | One physical configuration reached the RAM-initramfs diagnostic stage. |
| OPPO Pad Mini OPD2516 or other variants | Unsupported | None | No runtime evidence exists. Do not use this repository on another model. |

Support is tied to the documented hardware and firmware family. Bootloader
variants, panel revisions, partition layouts, and ABI-sensitive vendor
components must be revalidated.

## Hardware summary

| Component | Observed target |
|---|---|
| SoC | Qualcomm SM8845P, vendor platform `canoe`, upstream family Molokai |
| CPU | Eight ARM64 cores |
| GPU | Adreno 829, vendor generation 8.9.0 |
| Memory | LPDDR target; exact population must be checked per unit |
| Storage | Qualcomm UFS host |
| Display | 1680 x 2520 command-mode MIPI DSI, XN254 panel binding |
| DPU / DSI | SDE/DPU D10, DSI v2.10, PHY v7.2, four lanes |
| Compression | VESA DSC 1.2, 8 bits per pixel, two 840 x 24 slices per line |
| Touch | Goodix GT9966 identified in vendor data |
| Wireless | WCN7750-family integration identified in vendor data |
| Audio | Two TFA98xx amplifier descriptions in vendor data |

See [docs/hardware.md](docs/hardware.md) for source qualifications and the
strict distinction between vendor-tree identification and mainline support.

## Current status

| Area | Status | Evidence boundary |
|---|---|---|
| Bootloader and reversible test partition | Working | Fastboot access, `boot_b` writes, reboot, and restoration were exercised on the tested unit. |
| Linux ARM64 boot | Partial | The patched mainline kernel reaches a RAM initramfs and USB ACM shell. A persistent distribution boot is not validated. |
| Internal display | Broken | Firmware splash appears, then the panel turns black after native takeover. |
| DPU | Partial | LM and INTF CRC signatures distinguish native blue and red frames. |
| MIPI DSI / DSC | Partial | Controller configuration is plausible, but packet delivery to the panel is unproven. |
| Touchscreen | WIP | The controller is identified; no mainline input path is validated. |
| Adreno GPU | Blocked | The target GPU catalog and GMU firmware path are incomplete for the selected baseline. |
| OpenGL / Vulkan | Blocked | Hardware rendering is blocked by GPU bring-up. |
| USB device console | Partial | USB ACM diagnostic access works. Host mode and gamepads are unverified. |
| Wi-Fi / Bluetooth | Not Tested | No mainline connectivity result exists. |
| Audio | Not Tested | No end-to-end playback or capture result exists. |
| Battery / charging / thermal | Not Tested | Vendor protection and power-management components remain unreplaced. |
| Suspend / resume | Not Tested | No repeated suspend cycle has been validated. |
| Armada OS / desktop / Steam | Blocked | There is no usable Linux user session on the device yet. |

The complete matrix and promotion rules are in [docs/status.md](docs/status.md).

## Known issues

- The XN254 panel remains black after the firmware splash handoff.
- DPU frame CRCs do not prove DSI transport, panel reception, or illumination.
- The current image needs a developer-provided stock boot image as an AVB
  packaging shell and cannot be distributed as a general installer.
- The tested `boot_b` workflow is specific to the local experimental device. It
  is not a safe procedure for another unit without a new recovery validation.
- Adreno 829 catalog, GMU firmware, and mainline acceleration remain incomplete.
- Touch, Wi-Fi, Bluetooth, audio, charging control, and suspend are not ready.
- Armada OS, Gamescope, FEX, Proton, DXVK, and VKD3D-Proton integration has not
  reached a usable-device milestone.

## Repository layout

```text
.
├── device/opd2515/        Device-specific initramfs and diagnostic sources
├── docs/                  Status, evidence, build, recovery, and design notes
├── firmware/              Firmware policy; no proprietary firmware is stored
├── kernel/configs/        Tested diagnostic kernel configuration
├── kernel/patches/        Fixed-baseline patch and experiment patches
├── scripts/               Fetch, patch, build, package, and validation tools
├── tests/                 Repository, script, patch, and Markdown checks
└── .github/               CI and contribution templates
```

## Prerequisites

The current build path targets Linux on an x86_64 host with an AArch64 cross
toolchain. The tested environment used GCC 13 for cross compilation, GNU make,
Python 3, Device Tree Compiler, `cpio`, gzip, bzip2, and standard kernel build
dependencies.

Run the dependency check with:

```sh
./scripts/setup.sh
```

Use `./scripts/setup.sh --install-deps` on an Ubuntu or Debian host to install
the documented packages through the system package manager.

## Build overview

The source baseline is fixed to Linux commit
`6a876df4686788cd39128b62d7fcbff62f39278f`. The patch applies to that exact
tree and is a diagnostic baseline, not an upstream submission series.

```sh
./scripts/setup.sh
./scripts/fetch-sources.sh
./scripts/build-kernel.sh
```

A boot-partition image for the local test path also requires the developer's
legally obtained stock `boot_b` image:

```sh
./scripts/build-image.sh \
  --stock /path/to/stock-boot_b.img \
  --kernel artifacts/Image \
  --dtb artifacts/molokai-oppo-opd2515-diag.dtb
```

Read [docs/building.md](docs/building.md) before building and
[docs/installation.md](docs/installation.md) before considering a device test.
No boot-partition write is part of the default build workflow.

## Installation

There is no supported end-user installation. Developer testing is limited to
devices with a verified original `boot_b` backup, a tested return-to-Fastboot
path, and explicit authorization for each partition write. See
[docs/installation.md](docs/installation.md).

## Recovery

A diagnostic candidate can lose display, USB, or automatic boot progress. The
operator must know how to enter standard Fastboot with the physical keys before
writing `boot_b`. Restore the original image only after verifying its hash. See
[docs/recovery.md](docs/recovery.md).

## Development roadmap

1. Complete DSI command/DSC transport and XN254 visible-output bring-up.
2. Validate brightness, blanking, panel power sequencing, and cold boot.
3. Build a minimal persistent ARM64 userspace and touchscreen input path.
4. Enable Adreno GPU, OpenGL, and Vulkan through reviewed mainline interfaces.
5. Bring up wireless, audio, USB host, battery, charging, thermal, and suspend.
6. Integrate Armada OS and the graphics/game stack only after the hardware
   foundation is stable.

See [docs/roadmap.md](docs/roadmap.md) for acceptance criteria.

## Contributing

Contributions should preserve the evidence classes in
[docs/evidence.md](docs/evidence.md), apply to the fixed kernel baseline, avoid
private device data, and keep one behavioral variable per hardware experiment.
See [CONTRIBUTING.md](CONTRIBUTING.md).

Raw diagnostic logs, photos, firmware, partition backups, and local build trees
are retained outside this repository. Reports should include sanitized command
output, hashes, the exact patch, the firmware family, and the observed result.

## Credits

This work builds on the Linux kernel community, Qualcomm platform and DRM/MSM
source, Mesa/Freedreno, OPPO's published kernel sources, Armada OS and related
gaming-stack research, and prior OPD2515 investigations. Source locations and
pins are listed in [docs/sources.md](docs/sources.md). Naming an upstream
project does not imply endorsement.

## License

Original repository code is licensed under GPL-2.0-only unless a file carries a
different SPDX identifier. Kernel-derived code remains under its upstream
license and copyright. Documentation and third-party material retain their
indicated licenses. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Disclaimer

Flashing or booting an experimental kernel can render a device temporarily or
permanently unusable, corrupt data, or prevent recovery. This project does not
provide a production image or a guarantee that any other OPD2515 unit has the
same boot chain, panel, firmware, or partition layout. Device owners are
responsible for backups, authorization, and recovery.
