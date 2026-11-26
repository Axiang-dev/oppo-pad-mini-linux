#!/usr/bin/env bash
# Validate shell syntax, ShellCheck findings, and Python syntax.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

mapfile -d '' bash_scripts < <(find scripts device tests -type f -name '*.sh' -print0 | sort -z)
mapfile -d '' posix_scripts < <(
    find device/opd2515/initramfs -maxdepth 1 -type f \
        \( -name 'init' -o -name '*.sh' \) -print0 | sort -z
)
mapfile -d '' python_files < <(find scripts tests -type f -name '*.py' -print0 | sort -z)

for script in "${bash_scripts[@]}"; do
    bash -n "$script"
done

for script in "${posix_scripts[@]}"; do
    sh -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck --version
    shellcheck --external-sources --severity=warning --shell=bash "${bash_scripts[@]}"
    shellcheck --external-sources --severity=warning --shell=sh "${posix_scripts[@]}"
else
    printf 'error: ShellCheck is required for the repository checks\n' >&2
    exit 1
fi

python3 - "${python_files[@]}" <<'PY'
from pathlib import Path
import ast
import sys

for name in sys.argv[1:]:
    source = Path(name).read_text(encoding="utf-8")
    ast.parse(source, filename=name)

print(f"Python syntax OK ({len(sys.argv) - 1} files)")
PY

printf 'Shell and Python checks passed\n'
