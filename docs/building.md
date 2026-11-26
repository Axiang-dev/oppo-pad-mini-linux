# Building

This page describes the public diagnostic build. It reproduces a kernel that is
known to reach a RAM initramfs when packaging inputs match the tested OPD2515
configuration. It does not produce a supported distribution or a generally safe
boot image.

## Host and toolchain

The tested build path uses Linux on an x86_64 host and cross-compiles for ARM64.
The local source was built with GCC 13 and a recent GNU binutils AArch64 cross
toolchain. The configuration is also intended to work with the distro Clang/LLD
toolchain when explicitly selected.

Required host facilities:

- Git
- GNU make
- Python 3.10 or newer
- Bash
- AArch64 cross GCC and binutils
- bc, bison, flex, and pkg-config
- Device Tree Compiler
- cpio, gzip, bzip2, and xz
- OpenSSL and libelf development headers for the kernel build
- Perl and rsync

On Ubuntu or Debian, `scripts/setup.sh --install-deps` installs the tested
package set. `scripts/setup.sh` without arguments only checks the environment.

The build workspace defaults to `work/` at the repository root. Set
`OPD2515_WORKDIR` to place the source and output on a large local filesystem.
Avoid network shares and case-insensitive filesystems for kernel builds.

## Fixed source baseline

| Component | Repository | Revision | Use |
|---|---|---|---|
| Linux | https://github.com/torvalds/linux.git | `6a876df4686788cd39128b62d7fcbff62f39278f` | Diagnostic kernel baseline |
| OPPO modules and device tree | https://github.com/oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845.git | `ffca906674b2711c412b1c54cbfead5ec88e2081` | Read-only hardware and panel research |
| OPPO SM8845 kernel overlay | https://github.com/oppo-source/android_kernel_oppo_sm8845.git | `bff9b4473be9fac40cfe739d454ff5eed597b7a5` | Read-only integration research |
| OPPO common kernel | https://github.com/oppo-source/android_kernel_common_oppo_sm8845.git | `b5053c30d9d1fd52b40243b9e4850d2cad60db6e` | Read-only driver research |

The build uses the Linux repository. The OPPO repositories are fetched only for
source comparison and are not mixed into the diagnostic kernel build.

## Source and patch workflow

```sh
./scripts/fetch-sources.sh
./scripts/apply-patches.sh
```

`fetch-sources.sh` obtains the exact Linux commit. `apply-patches.sh` verifies
`kernel/patches/SHA256SUMS`, checks whether the baseline is already applied, and
applies only `kernel/patches/0001-arm64-qcom-add-opd2515-diagnostic-baseline.patch`.

The main patch is a single diagnostic baseline generated from the verified local
development state through EXP-056. It is intentionally not split into an
upstream-ready series. Changes mix board support, incomplete mainline plumbing,
and diagnostic instrumentation. Review individual hunks before reusing anything
on another device.

Additional patches under `kernel/patches/exp053/` and
`kernel/patches/experiments/` are not applied by default. They encode individual
experiments and may depend on each other or on a match to the main baseline.

## Build command

```sh
./scripts/build-kernel.sh
```

The script performs these steps:

1. Fetches the fixed source unless `--no-fetch` is given.
2. Applies the diagnostic baseline unless `--no-patch` is given.
3. Copies `kernel/configs/opd2515-diag68-exp053.config` to the out-of-tree
   build directory.
4. Runs `make olddefconfig`.
5. Builds the OPD2515 DTB before the ARM64 Image because the diagnostic kernel
   embeds that DTB.
6. Builds the Image and the fixed module set used by the RAM initramfs.
7. Builds a static AArch64 BusyBox from the pinned BusyBox 1.37.0 release.
8. Builds the return-to-bootloader helper and assembles the initramfs tree.
9. Regenerates the Image with the initramfs embedded.
10. Writes artifacts and SHA256 checksums under `artifacts/`.

For a faster kernel and DTB syntax/build check without initramfs assembly, use:

```sh
./scripts/build-kernel.sh --kernel-only
```

The tested configuration uses `CONFIG_INITRAMFS_SOURCE=""` in the tracked file.
The build script changes only the generated `out/.config` after assembling the
initramfs. It does not rewrite the public configuration.

## Generated files

Default output names:

```text
artifacts/Image
artifacts/molokai-oppo-opd2515-diag.dtb
artifacts/opd2515-diag68-exp053.config
artifacts/initramfs/initramfs-opd2515.cpio.gz
artifacts/initramfs/manifest
artifacts/modules/*.ko
artifacts/SHA256SUMS
```

These files are ignored by Git. Report the source commit, patch SHA256,
configuration SHA256, Image SHA256, DTB SHA256, module set, and initramfs SHA256
with every hardware result.

## Device-tree build

The direct target is:

```sh
make -C work/linux O=work/build \
  ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
  qcom/molokai-oppo-opd2515-diag.dtb
```

The built-in FDT integration requires this file before `Image` is linked. A
Device Tree compile does not prove that the bootloader supplies a compatible
memory map. The kernel's fail-closed handoff validates the selected RAM nodes and
reservations before accepting the embedded tree.

## Initramfs

`scripts/build-initramfs.sh` compiles a static init, copies the required modules,
downloads and verifies BusyBox 1.37.0, compiles it for AArch64, creates symlinks,
and writes an uncompressed-tree manifest plus a gzip cpio archive.

The initramfs is self-contained and does not mount Android `userdata`. It
configures a USB ACM gadget, loads the diagnostic display modules, and exposes a
shell on the ACM console or kernel console. A small static helper requests
`RESTART2` with `bootloader` for the tested recovery path.

## Boot image packaging

The tested boot partition is an Android boot image v4 with no external ramdisk
and an AVB footer. `scripts/package_boot.py` retains the stock header and AVB
structure, places `Image` and the diagnostic DTB in the kernel region, and
rebuilds the hash descriptor with algorithm `NONE` as used by the unlocked test
path.

Packaging requires a legally obtained stock `boot_b` image from the same firmware
family:

```sh
./scripts/build-image.sh \
  --stock /path/to/stock-boot_b.img \
  --kernel artifacts/Image \
  --dtb artifacts/molokai-oppo-opd2515-diag.dtb
```

The script refuses an unexpected partition size, boot header version, ramdisk
state, boot signature, DTB magic, or AVB hash descriptor. It writes a JSON report
next to the image.

The output is a developer test artifact. Its existence does not authorize a
partition write.

## Reproducibility limits

- The vendor device tree and OPPO source remain separate pinned research inputs.
- Proprietary runtime firmware and vendor modules are not redistributed.
- The current tested hardware is one OPD2515 configuration running the documented
  ColorOS firmware family.
- Full Armada OS userspace construction is not implemented.
- The diagnostic baseline is not an upstream patch series.
- Builds can vary in toolchain-generated metadata unless the toolchain version and
  build environment are recorded.

## Validation

```sh
./tests/check-scripts.sh
python3 tests/check-repository.py
./tests/check-patches.sh
./tests/check-markdown.sh
```

CI patch and kernel builds verify source compatibility only. A successful CI run
does not establish boot or display operation on hardware.
