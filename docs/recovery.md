# Recovery

The tested OPD2515 experiments use a reversible stock-image restoration path.
Recovery capability must be established before a candidate is written.

## Required backups

At minimum, preserve and hash the image for each partition modified by the
workflow. The documented experiment path writes only `boot_b`, so its original
image and SHA256 are mandatory. Preserve enough original images and firmware
metadata to understand the tested boot configuration. Do not store these files
in Git.

```sh
sha256sum stock-boot_b.img > stock-boot_b.img.sha256
sha256sum -c stock-boot_b.img.sha256
```

Keep a second copy. Do not overwrite the only known-good backup with a generated
candidate.

## Enter standard Fastboot

The tested unit supports a diagnostic helper that requests the `bootloader`
restart reason. When Linux controls the device, the initramfs helper can invoke:

```sh
/bin/return-bootloader
```

A host-side reboot request is not a substitute for this tested path.

When Linux, the native display, or USB ACM is unavailable, use the physical key
sequence for standard Fastboot. The exact key behavior is device-specific and
must be confirmed before experimentation. Do not assume that connection to a
different USB mode or a black screen means Fastboot is available.

## Restore the original boot image

After confirming that the host sees the expected standard Fastboot endpoint:

```sh
fastboot devices
fastboot flash boot_b /path/to/verified-stock-boot_b.img
fastboot reboot
```

The serial is deliberately omitted. Confirm the selected endpoint before issuing
any command. A write requires explicit authorization for that operation.

After reboot, confirm that the original operating system starts. A partition
write reply alone is not recovery completion. If practical, read the modified
partition back and compare its hash with the original backup. Never flash the
stock image to a guessed slot.

## If standard Fastboot is unavailable

1. Stop. Do not issue more partition writes.
2. Preserve the current host output and device state.
3. Use the previously tested physical-key sequence with the device connected to a
   known-good host cable and port.
4. If physical-key entry still fails, treat recovery as unresolved and require a
   new reviewed procedure before further hardware action.

An EDL or 9008 mode is not assumed to be available, authorized, or recoverable.
Do not present it as a guaranteed fallback.

## Recovery acceptance

Recovery is complete only when all of these are true:

- the standard Fastboot endpoint was available
- the original image was restored
- the reported write completed without error
- the device rebooted into the original software
- the restored configuration is confirmed by the owner or an independent read

The test also preserves the history of any failed path rather than deleting its
logs or photographs.
