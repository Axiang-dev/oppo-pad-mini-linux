#!/usr/bin/env bash
# Verify and apply the fixed-baseline OPD2515 diagnostic patch.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

check_only=0
case "${1:-}" in
    --check) check_only=1 ;;
    -h|--help)
        printf 'Usage: %s [--check]\n' "$0"
        exit 0
        ;;
    '') ;;
    *) die "unknown option: $1" ;;
esac

require_cmd git
require_cmd sha256sum
[[ -d "$KERNEL_SRC/.git" ]] || die "Linux source is missing, run scripts/fetch-sources.sh"

patch_dir=$REPO_ROOT/kernel/patches
patch_file=$patch_dir/0001-arm64-qcom-add-opd2515-diagnostic-baseline.patch
sums_file=$patch_dir/SHA256SUMS

[[ -f "$patch_file" ]] || die "baseline patch is missing"
[[ -f "$sums_file" ]] || die "patch checksum file is missing"

(cd "$patch_dir" && sha256sum -c SHA256SUMS)

actual_base=$(git -C "$KERNEL_SRC" rev-parse HEAD)
[[ $actual_base == "$LINUX_COMMIT" ]] || \
    die "kernel HEAD $actual_base does not match required baseline $LINUX_COMMIT"

if git -C "$KERNEL_SRC" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
    log "diagnostic baseline is already applied"
    exit 0
fi

git -C "$KERNEL_SRC" apply --check "$patch_file"

if (( check_only )); then
    log "baseline patch applies cleanly"
    exit 0
fi

git -C "$KERNEL_SRC" apply "$patch_file"
git -C "$KERNEL_SRC" diff --check
log "applied $patch_file"
