#!/usr/bin/env bash
# Verify tracked patch checksums and apply the baseline to the pinned Linux tree.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

command -v sha256sum >/dev/null 2>&1 || {
    printf 'error: sha256sum is required\n' >&2
    exit 1
}

[[ -f kernel/patches/SHA256SUMS ]] || {
    printf 'error: kernel/patches/SHA256SUMS is missing\n' >&2
    exit 1
}

(
    cd kernel/patches
    sha256sum --check SHA256SUMS
)

placeholder_author="maintainers"
placeholder_author="${placeholder_author}@invalid"
if grep -R -n -E "${placeholder_author}|Subject: \[WIP\]" kernel/patches >/dev/null 2>&1; then
    printf 'error: placeholder author or WIP marker remains in patches\n' >&2
    exit 1
fi

if [[ -n ${OPD2515_KERNEL_SRC:-} || -d ${OPD2515_WORKDIR:-work}/linux ]]; then
    ./scripts/apply-patches.sh --check
else
    printf 'Patch checksum checks passed; source application deferred to CI or a source checkout.\n'
fi
