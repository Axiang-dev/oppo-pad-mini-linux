# Installation and developer testing

There is no end-user installation procedure for OPD2515. The repository does
not publish a production image, installer, recovery package, proprietary
firmware, or a supported partition layout.

The tested workflow is a developer bring-up path on one physical unit. It uses
`boot_b` as a reversible experiment slot and restores the original image after a
test. Another unit can have a different bootloader, ABI, panel, partition table,
or firmware behavior even when it carries the same retail name.

## Mandatory gates

Every device test requires all of the following:

1. A byte-for-byte original `boot_b` backup and a separately recorded SHA256.
2. A known way to enter standard Fastboot with physical keys when display and USB
   ACM are unavailable.
3. A tested recovery return to the original software.
4. A candidate hash recorded in the test log before any write.
5. One behavioral variable per experiment.
6. Explicit authorization for each individual `boot_b` write.
7. A standard Fastboot endpoint as the required test-stop state unless the owner
   requests a different state.

Do not modify the partition table, active slot, AVB trust configuration, secure
boot state, or any boot-chain partition as part of display bring-up.

## Prepare a test candidate

Build and inspect the candidate on the host:

```sh
./scripts/setup.sh
./scripts/fetch-sources.sh
./scripts/build-kernel.sh
./scripts/build-image.sh \
  --stock /path/to/stock-boot_b.img \
  --kernel artifacts/Image \
  --dtb artifacts/molokai-oppo-opd2515-diag.dtb

sha256sum artifacts/boot-opd2515-diagnostic.img
```

Record:

- device model and firmware family
- original `boot_b` SHA256
- Linux source commit
- baseline patch SHA256
- kernel configuration SHA256
- Image, DTB, initramfs, modules, and packaged-image SHA256
- expected serial/console behavior
- expected display phases
- recovery method

A candidate that does not preserve the expected boot image structure or whose hash
does not match the review record is rejected.

## Test sequence

The operator runs the test only after obtaining authorization for that exact
candidate. The write target is the documented experiment slot, not the active
production slot and not a boot-chain partition.

At test end, capture the result through the available channel, restore the original
image, reboot, and verify that the original software is available. If the device
does not reach standard Fastboot, stop and use the documented physical-key path.
Do not guess a different partition or try an unreviewed EDL sequence.

## Evidence capture

For a display candidate, record separately:

- visual result at each firmware and native phase
- kernel and initramfs hashes
- module load results
- DPU LM, INTF, and DSI sample values
- frame completion and TE counters
- SMMU, DSI FIFO, PLL, vblank, underflow, and timeout errors
- USB ACM availability
- final device state

A black screen with a live USB shell is a valid negative result. A frame counter
with no visible panel output is not a display success.

## What is not installable

The repository does not yet provide:

- a persistent root filesystem
- an installer that protects Android partitions
- a slot-switching scheme
- a production kernel package
- GPU or touchscreen acceptance
- an Armada OS image
- a safe generic recovery bundle

Any claim that the project is ready for ordinary daily use, gaming, or production
is unsupported by the current evidence.
