#!/usr/bin/env bash
# Fetch pinned Linux and optional OPPO source trees without modifying project files.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

with_vendor=0
case "${1:-}" in
    --vendor) with_vendor=1 ;;
    -h|--help)
        printf 'Usage: %s [--vendor]\n' "$0"
        printf '  --vendor  also fetch the three pinned OPPO research trees\n'
        exit 0
        ;;
    '') ;;
    *) die "unknown option: $1" ;;
esac

require_cmd git
mkdir -p "$WORKDIR"

fetch_exact_commit() {
    local name=$1
    local url=$2
    local commit=$3
    local destination=$4

    if [[ -e "$destination" && ! -d "$destination/.git" ]]; then
        die "$destination exists and is not a Git checkout"
    fi

    if [[ ! -d "$destination/.git" ]]; then
        log "initializing $name at $destination"
        mkdir -p "$destination"
        git -C "$destination" init -q
        git -C "$destination" remote add origin "$url"
    else
        git -C "$destination" remote set-url origin "$url"
    fi

    check_clean_git_tree "$destination"

    if ! git -C "$destination" cat-file -e "$commit^{commit}" 2>/dev/null; then
        git -C "$destination" fetch --depth=1 origin "$commit"
    fi

    git -C "$destination" -c advice.detachedHead=false checkout --detach "$commit"
    actual=$(git -C "$destination" rev-parse HEAD)
    [[ $actual == "$commit" ]] || die "$name HEAD is $actual, expected $commit"
    log "$name ready at $actual"
}

fetch_exact_commit Linux "$LINUX_REPO" "$LINUX_COMMIT" "$KERNEL_SRC"

if (( with_vendor )); then
    fetch_exact_commit OPPO-overlay "$OPPO_OVERLAY_REPO" "$OPPO_OVERLAY_COMMIT" \
        "$WORKDIR/vendor/oppo-overlay"
    fetch_exact_commit OPPO-common "$OPPO_COMMON_REPO" "$OPPO_COMMON_COMMIT" \
        "$WORKDIR/vendor/oppo-common"
    fetch_exact_commit OPPO-modules-dt "$OPPO_MODULES_DT_REPO" "$OPPO_MODULES_DT_COMMIT" \
        "$WORKDIR/vendor/oppo-modules-dt"
fi

cat >"$WORKDIR/SOURCES.lock" <<EOF
linux_repo=$LINUX_REPO
linux_commit=$LINUX_COMMIT
oppo_overlay_repo=$OPPO_OVERLAY_REPO
oppo_overlay_commit=$OPPO_OVERLAY_COMMIT
oppo_common_repo=$OPPO_COMMON_REPO
oppo_common_commit=$OPPO_COMMON_COMMIT
oppo_modules_dt_repo=$OPPO_MODULES_DT_REPO
oppo_modules_dt_commit=$OPPO_MODULES_DT_COMMIT
EOF

log "source lock written to $WORKDIR/SOURCES.lock"
