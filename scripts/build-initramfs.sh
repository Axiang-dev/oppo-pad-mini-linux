#!/usr/bin/env bash
# Build the self-contained OPD2515 diagnostic initramfs from kernel output.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

kernel_out=$KERNEL_OUT
output_root=$ARTIFACT_DIR/initramfs
case "${1:-}" in
    -h|--help)
        printf 'Usage: OPD2515_KERNEL_OUT=DIR %s\n' "$0"
        exit 0
        ;;
    '') ;;
    *) die "unknown option: $1" ;;
esac

require_cmd bzip2
require_cmd cpio
require_cmd curl
require_cmd file
require_cmd gzip
require_cmd make
require_cmd sha256sum
require_cmd tar
require_cmd "${CROSS_COMPILE}gcc"

busybox_version=1.37.0
busybox_sha256=3311dff32e746499f4df0d5df04d7eb396382d7e108bb9250e7b519b837043a4
busybox_archive=$WORKDIR/downloads/busybox-$busybox_version.tar.bz2
busybox_src=$WORKDIR/busybox-$busybox_version
busybox_binary=$busybox_src/busybox
init_root=$output_root/staging
manifest=$output_root/manifest
archive=$output_root/initramfs-opd2515.cpio.gz

case "$init_root" in
    "$ARTIFACT_DIR"/*) ;;
    *) die "refusing staging path outside the artifact directory: $init_root" ;;
esac
if [[ $init_root == *[[:space:]]* ]]; then
    die "the initramfs staging path must not contain whitespace"
fi
[[ -d $kernel_out ]] || die "kernel output directory is missing: $kernel_out"

mkdir -p "$WORKDIR/downloads" "$output_root"

if [[ ! -f $busybox_archive ]]; then
    curl --fail --location --retry 3 --output "$busybox_archive.part" \
        "https://busybox.net/downloads/busybox-$busybox_version.tar.bz2"
    mv "$busybox_archive.part" "$busybox_archive"
fi

archive_hash=$(sha256sum "$busybox_archive" | awk '{print $1}')
[[ $archive_hash == "$busybox_sha256" ]] || die "BusyBox archive SHA256 mismatch"

if [[ ! -d $busybox_src ]]; then
    tar -C "$WORKDIR" -xjf "$busybox_archive"
fi

if [[ ! -x $busybox_binary ]] || [[ $busybox_src/busybox -ot $busybox_src/.config ]]; then
    make -C "$busybox_src" CROSS_COMPILE="$CROSS_COMPILE" defconfig
    sed -i 's/^# CONFIG_STATIC is not set$/CONFIG_STATIC=y/' "$busybox_src/.config"
    grep -q '^CONFIG_STATIC=y$' "$busybox_src/.config" || die "could not enable static BusyBox"
    make -C "$busybox_src" CROSS_COMPILE="$CROSS_COMPILE" olddefconfig
    make -C "$busybox_src" CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS"
fi

file "$busybox_binary" | grep -q 'ARM aarch64' || die "BusyBox is not an AArch64 binary"

rm -rf -- "$init_root"
mkdir -p "$init_root"/{bin,dev,modules,proc,run,sys}
install -m 0755 "$busybox_binary" "$init_root/bin/busybox"

for applet in \
    awk base64 cat chmod cp cut dmesg grep head insmod ln ls md5sum mkdir \
    mknod mount rm rmmod sed seq setsid sha256sum sh sleep tr uname wc; do
    ln -s busybox "$init_root/bin/$applet"
done

install -m 0755 "$REPO_ROOT/device/opd2515/initramfs/init" "$init_root/init"
install -m 0755 "$REPO_ROOT/device/opd2515/initramfs/load-display.sh" \
    "$init_root/modules/load-display.sh"

"${CROSS_COMPILE}gcc" -static -O2 -Wall -Wextra -Werror \
    -o "$init_root/bin/return-bootloader" \
    "$REPO_ROOT/device/opd2515/initramfs/return-bootloader.c"

module_targets=(
    drivers/media/cec/core/cec.ko
    drivers/clk/qcom/dispcc-kaanapali.ko
    drivers/gpu/drm/clients/drm_client_lib.ko
    drivers/gpu/drm/display/drm_display_helper.ko
    drivers/gpu/drm/drm_exec.ko
    drivers/gpu/drm/drm_gpuvm.ko
    drivers/gpu/drm/scheduler/gpu-sched.ko
    drivers/soc/qcom/mdt_loader.ko
    drivers/gpu/drm/msm/msm.ko
    drivers/gpu/drm/panel/panel-oppo-xn254.ko
    drivers/soc/qcom/ubwc_config.ko
)

for module_path in "${module_targets[@]}"; do
    source_module=$kernel_out/$module_path
    [[ -s $source_module ]] || die "required module is missing: $source_module"
    install -m 0644 "$source_module" "$init_root/modules/$(basename "$module_path")"
done

find "$init_root" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
python3 "$REPO_ROOT/scripts/generate_initramfs_manifest.py" \
    --root "$init_root" --output "$manifest"

(
    cd "$init_root"
    find . -mindepth 1 -print0 | sort -z |
        cpio --null --create --format=newc --owner=0:0 --quiet |
        gzip -n -9
) > "$archive"

sha256sum "$archive" > "$archive.sha256"
log "initramfs archive: $archive"
log "kernel embed manifest: $manifest"
cat "$archive.sha256"
