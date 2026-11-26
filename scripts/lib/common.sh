#!/usr/bin/env bash
# Shared paths and helpers for OPD2515 development scripts.
# shellcheck disable=SC2034  # Intentionally consumed by sourcing scripts.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
WORKDIR=${OPD2515_WORKDIR:-"$REPO_ROOT/work"}
KERNEL_SRC=${OPD2515_KERNEL_SRC:-"$WORKDIR/linux"}
KERNEL_OUT=${OPD2515_KERNEL_OUT:-"$WORKDIR/build"}
ARTIFACT_DIR=${OPD2515_ARTIFACT_DIR:-"$REPO_ROOT/artifacts"}
CROSS_COMPILE=${CROSS_COMPILE:-aarch64-linux-gnu-}
JOBS=${OPD2515_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')}
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-1795219200}
export SOURCE_DATE_EPOCH

LINUX_REPO=https://github.com/torvalds/linux.git
LINUX_COMMIT=6a876df4686788cd39128b62d7fcbff62f39278f
OPPO_OVERLAY_REPO=https://github.com/oppo-source/android_kernel_oppo_sm8845.git
OPPO_OVERLAY_COMMIT=bff9b4473be9fac40cfe739d454ff5eed597b7a5
OPPO_COMMON_REPO=https://github.com/oppo-source/android_kernel_common_oppo_sm8845.git
OPPO_COMMON_COMMIT=b5053c30d9d1fd52b40243b9e4850d2cad60db6e
OPPO_MODULES_DT_REPO=https://github.com/oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845.git
OPPO_MODULES_DT_COMMIT=ffca906674b2711c412b1c54cbfead5ec88e2081

log() {
    printf '[opd2515] %s\n' "$*"
}

warn() {
    printf '[opd2515][warning] %s\n' "$*" >&2
}

die() {
    printf '[opd2515][error] %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

sha256_file() {
    local file=$1
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file"
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file"
    else
        die "sha256sum or shasum is required"
    fi
}

check_clean_git_tree() {
    local tree=$1
    git -C "$tree" diff --quiet --ignore-submodules -- || die "dirty worktree: $tree"
    git -C "$tree" diff --cached --quiet --ignore-submodules -- || die "staged changes: $tree"
}
