# Firmware policy

No proprietary firmware or complete partition image is stored in this
repository.

A local developer may extract files from a legally obtained device image for
personal testing. `scripts/fetch-sources.sh` does not download vendor firmware.
`scripts/build-image.sh` requires a user-provided stock `boot_b` image solely
as the packaging shell for the verified image format.

Do not publish extracted firmware, boot images, modem or DSP images, partition
backups, or files containing device-specific identity data. Record the source
build and SHA256 locally when selecting files for a test.