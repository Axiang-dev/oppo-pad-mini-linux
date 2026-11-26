#!/usr/bin/env bash
# Build the fixed-baseline OPD2515 diagnostic kernel and initramfs.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

kernel_only=0
skip_fetch=0
skip_patch=0
reset_config=0
while (( $# )); do
    case "$1" in
        --kernel-only) kernel_only=1 ;;
        --no-fetch) skip_fetch=1 ;;
        --no-patch) skip_patch=1 ;;
        --reset-config) reset_config=1 ;;
        -h|--help)
            printf 'Usage: %s [--kernel-only] [--no-fetch] [--no-patch] [--reset-config]\n' "$0"
            exit 0
            ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

require_cmd make
require_cmd python3
require_cmd "${CROSS_COMPILE}gcc"
require_cmd "${CROSS_COMPILE}ld"

if (( ! skip_fetch )); then
    "$REPO_ROOT/scripts/fetch-sources.sh"
fi
if (( ! skip_patch )); then
    "$REPO_ROOT/scripts/apply-patches.sh"
fi

config_source=$REPO_ROOT/kernel/configs/opd2515-diag68-exp053.config
dtb_relative=arch/arm64/boot/dts/qcom/molokai-oppo-opd2515-diag.dtb
dtb_target=qcom/molokai-oppo-opd2515-diag.dtb
mkdir -p "$KERNEL_OUT" "$ARTIFACT_DIR/modules"

if [[ -f $KERNEL_OUT/.config ]]; then
    if ! cmp -s "$config_source" "$KERNEL_OUT/.config"; then
        if (( reset_config )); then
            cp "$config_source" "$KERNEL_OUT/.config"
        else
            die "$KERNEL_OUT/.config differs from the tracked diagnostic configuration; rerun with --reset-config only if that is intentional"
        fi
    fi
else
    cp "$config_source" "$KERNEL_OUT/.config"
fi

make_args=(
    make -C "$KERNEL_SRC" O="$KERNEL_OUT" ARCH=arm64
    CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS"
)

"${make_args[@]}" olddefconfig
"${make_args[@]}" "$dtb_target"
"${make_args[@]}" Image

dtb=$KERNEL_OUT/$dtb_relative
image=$KERNEL_OUT/arch/arm64/boot/Image
[[ -s $dtb ]] || die "DTB was not produced: $dtb"
[[ -s $image ]] || die "Image was not produced: $image"

install -m 0644 "$image" "$ARTIFACT_DIR/Image"
install -m 0644 "$dtb" "$ARTIFACT_DIR/molokai-oppo-opd2515-diag.dtb"
install -m 0644 "$KERNEL_OUT/.config" "$ARTIFACT_DIR/opd2515-diag68-exp053.config"

if (( ! kernel_only )); then
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
    "${make_args[@]}" "${module_targets[@]}"

    OPD2515_KERNEL_OUT="$KERNEL_OUT" "$REPO_ROOT/scripts/build-initramfs.sh"
    manifest=$ARTIFACT_DIR/initramfs/manifest
    [[ -s $manifest ]] || die "initramfs manifest is missing: $manifest"

    "$KERNEL_SRC/scripts/config" --file "$KERNEL_OUT/.config" \
        --set-str INITRAMFS_SOURCE "$manifest"
    "${make_args[@]}" olddefconfig
    "${make_args[@]}" Image

    install -m 0644 "$KERNEL_OUT/arch/arm64/boot/Image" "$ARTIFACT_DIR/Image"
    install -m 0644 "$KERNEL_OUT/.config" "$ARTIFACT_DIR/opd2515-diag68-exp053.config"

    for module_path in "${module_targets[@]}"; do
        source_module=$KERNEL_OUT/$module_path
        [[ -s $source_module ]] || die "module was not produced: $source_module"
        install -m 0644 "$source_module" "$ARTIFACT_DIR/modules/$(basename "$module_path")"
    done
fi

{
    printf 'source_commit=%s\n' "$(git -C "$KERNEL_SRC" rev-parse HEAD)"
    printf 'config_sha256=%s\n' "$(sha256sum "$config_source" | awk '{print $1}')"
    printf 'patch_sha256=%s\n' "$(sha256sum "$REPO_ROOT/kernel/patches/0001-arm64-qcom-add-opd2515-diagnostic-baseline.patch" | awk '{print $1}')"
    printf 'image_sha256=%s\n' "$(sha256sum "$ARTIFACT_DIR/Image" | awk '{print $1}')"
    printf 'dtb_sha256=%s\n' "$(sha256sum "$ARTIFACT_DIR/molokai-oppo-opd2515-diag.dtb" | awk '{print $1}')"
    printf 'kernel_only=%s\n' "$kernel_only"
    printf 'host=%s\n' "$(uname -a)"
    printf 'compiler=%s\n' "$("${CROSS_COMPILE}gcc" --version | head -n 1)"
    printf 'jobs=%s\n' "$JOBS"
    printf 'source_date_epoch=%s\n' "$SOURCE_DATE_EPOCH"
} > "$ARTIFACT_DIR/BUILD-INFO.txt"

(
    cd "$ARTIFACT_DIR"
    find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum
) > "$ARTIFACT_DIR/SHA256SUMS"

log "kernel build complete"
cat "$ARTIFACT_DIR/BUILD-INFO.txt"
