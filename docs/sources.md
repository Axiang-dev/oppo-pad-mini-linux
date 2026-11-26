# Sources and provenance

All source revisions below are pinned. The main build uses the Linux revision and
the project patch. OPPO revisions are used for reading vendor device trees,
display-driver behavior, board resources, and power sequencing.

## Linux

| Item | Value |
|---|---|
| Repository | https://github.com/torvalds/linux.git |
| Branch context | v7.4-rc1 source used by the local diagnostic build |
| Commit | `6a876df4686788cd39128b62d7fcbff62f39278f` |
| License | Mixed GPL-2.0-only, other SPDX identifiers, and the Linux syscall note |

The repository does not vendor unrelated Linux source. `scripts/fetch-sources.sh`
obtains the exact commit and `kernel/patches/` records project changes.

## OPPO SM8845 sources

| Repository | Branch | Commit | Purpose |
|---|---|---|---|
| https://github.com/oppo-source/android_kernel_oppo_sm8845.git | `oppo/sm8845_b_16.0_pad_mini` | `bff9b4473be9fac40cfe739d454ff5eed597b7a5` | Kernel overlay comparison |
| https://github.com/oppo-source/android_kernel_common_oppo_sm8845.git | `oppo/sm8845_b_16.0_pad_mini` | `b5053c30d9d1fd52b40243b9e4850d2cad60db6e` | Common kernel and display research |
| https://github.com/oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845.git | `oppo/sm8845_b_16.0_pad_mini` | `ffca906674b2711c412b1c54cbfead5ec88e2081` | Device trees, panel data, and vendor modules |

The commit pins were checked with `git ls-remote` on 2026-11-26. To fetch them:

```sh
./scripts/fetch-sources.sh --vendor
```

These repositories are large and remain separate from the mainline output. Their
presence supports inspection and comparison. It does not make the diagnostic
patch an OPPO or Qualcomm submission.

## BusyBox

| Item | Value |
|---|---|
| Release | BusyBox 1.37.0 |
| URL | https://busybox.net/downloads/busybox-1.37.0.tar.bz2 |
| SHA256 | `3311dff32e746499f4df0d5df04d7eb396382d7e108bb9250e7b519b837043a4` |
| License | GPL-2.0 |

The initramfs builder downloads this source archive, verifies the SHA256, and
builds a static AArch64 executable. The binary is a generated artifact and is not
committed.

## Research areas

- Linux DRM/MSM DPU, DSI, DSC, PHY, and panel subsystems
- Qualcomm Molokai, Kaanapali, and alor/canoe device trees
- Mesa Freedreno and Turnip
- Armada OS, ROCKNIX, Gamescope, FEX, Proton, DXVK, and VKD3D-Proton
- Qualcomm power domains, interconnect, SMMU, UFS, USB, audio, and power supply

Search requests should use exact compatible strings, function names, register
names, DT properties, DSC/PPS field names, and error codes. A matching project
name alone is not evidence that its hardware programming sequence applies to
OPD2515.

## Material excluded from publication

- stock boot, vendor_boot, init_boot, boot chain, and partition images
- extracted vendor modules and firmware
- complete DTBO overlays that have not been cleared for redistribution
- raw device logs and photographs with possible identity data
- private keys, tokens, account data, and local build caches
- unlicensed third-party binaries

Users who need proprietary local inputs must extract them from their own legally
obtained software and keep them outside the repository.
