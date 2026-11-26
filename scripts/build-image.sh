#!/usr/bin/env bash
# Package the diagnostic Image and DTB using a verified stock boot_b shell.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

stock=
kernel=$ARTIFACT_DIR/Image
dtb=$ARTIFACT_DIR/molokai-oppo-opd2515-diag.dtb
output=$ARTIFACT_DIR/boot-opd2515-diagnostic.img
force=

while (( $# )); do
    case "$1" in
        --stock) stock=${2:-}; shift ;;
        --kernel) kernel=${2:-}; shift ;;
        --dtb) dtb=${2:-}; shift ;;
        --output) output=${2:-}; shift ;;
        --force) force=--force ;;
        -h|--help)
            printf 'Usage: %s --stock FILE [--kernel FILE] [--dtb FILE] [--output FILE] [--force]\n' "$0"
            exit 0
            ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

[[ -n $stock ]] || die "--stock is required"
[[ -f $stock ]] || die "stock image not found: $stock"
[[ -f $kernel ]] || die "kernel Image not found: $kernel"
[[ -f $dtb ]] || die "DTB not found: $dtb"
require_cmd python3

mkdir -p "$(dirname "$output")"
python3 "$REPO_ROOT/scripts/package_boot.py" \
    --stock "$stock" --kernel "$kernel" --dtb "$dtb" --out "$output" $force
