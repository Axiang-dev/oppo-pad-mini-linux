#!/usr/bin/env bash
# Check or install the host dependencies for the OPD2515 diagnostic build.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

install_deps=0
case "${1:-}" in
    --install-deps) install_deps=1 ;;
    -h|--help)
        printf 'Usage: %s [--install-deps]\n' "$0"
        exit 0
        ;;
    '') ;;
    *) die "unknown option: $1" ;;
esac

apt_packages=(
    bc binutils-aarch64-linux-gnu bison bzip2 cpio curl device-tree-compiler
    flex gcc gcc-aarch64-linux-gnu git libelf-dev libssl-dev make openssl
    pahole perl pkg-config python3 rsync xz-utils
)

if (( install_deps )); then
    require_cmd apt-get
    require_cmd sudo
    sudo apt-get update
    sudo apt-get install -y "${apt_packages[@]}"
fi

required=(
    git make python3 bash cpio gzip bzip2 xz dtc bc bison flex
    pkg-config perl rsync curl "${CROSS_COMPILE}gcc" "${CROSS_COMPILE}ld"
)
missing=()
for command_name in "${required[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        missing+=("$command_name")
    fi
done

if (( ${#missing[@]} )); then
    printf 'Missing commands:\n' >&2
    printf '  %s\n' "${missing[@]}" >&2
    printf '\nOn Ubuntu or Debian, run:\n  %s --install-deps\n' "$0" >&2
    exit 1
fi

python3 - <<'PY'
import sys
if sys.version_info < (3, 10):
    raise SystemExit("Python 3.10 or newer is required")
print(f"Python {sys.version.split()[0]}")
PY

printf 'Repository root: %s\n' "$REPO_ROOT"
printf 'Build workspace: %s\n' "$WORKDIR"
printf 'Cross compiler: %s\n' "$("${CROSS_COMPILE}gcc" --version | head -n 1)"
printf 'Host jobs: %s\n' "$JOBS"

available=$(df -Pk "$REPO_ROOT" | awk 'NR == 2 { print $4 }')
printf 'Free space at repository root: %s KiB\n' "$available"
if (( available < 10485760 )); then
    warn "less than 10 GiB is free, a kernel source tree and build output may not fit"
fi

log "host dependency check passed"
