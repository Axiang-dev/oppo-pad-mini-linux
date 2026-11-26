#!/usr/bin/env python3
"""Reject private data, secrets, binaries, and oversized files before publishing."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MAX_FILE_BYTES = 6 * 1024 * 1024
SKIP_ROOTS = {"artifacts", "build", "downloads", "out", "work"}
DENIED_SUFFIXES = {
    ".7z", ".a", ".bin", ".cpio", ".dtb", ".dtbo", ".ext4", ".fw",
    ".gz", ".img", ".iso", ".ko", ".o", ".pcap", ".pcapng", ".p7b",
    ".p12", ".rar", ".tar", ".xz", ".zip", ".zst",
}
TEXT_SUFFIXES = {
    "", ".c", ".config", ".editorconfig", ".gitattributes", ".gitignore",
    ".json", ".md", ".patch", ".py", ".sh", ".txt", ".yml", ".yaml",
}


def repository_files() -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=ROOT,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        files = []
        for current, directories, names in os.walk(ROOT):
            directories[:] = [name for name in directories if name != ".git" and name not in SKIP_ROOTS]
            for name in names:
                files.append(Path(current, name))
        return sorted(files)
    return [ROOT / os.fsdecode(name) for name in result.stdout.split(b"\0") if name]


def main() -> int:
    errors: list[str] = []
    files = repository_files()
    if not files:
        print("error: no repository files found", file=sys.stderr)
        return 1

    windows_absolute = re.compile(r"(?<![A-Za-z])[A-Za-z]:[\\/][^\s\"']+")
    private_unix_roots = ("/" + "srv/", "/" + "mnt/")
    github_token = re.compile(r"(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})")
    private_key = "BEGIN " + "PRIVATE KEY"
    device_id = "42d7" + "2758"
    placeholder_author = "maintainers" + "@invalid"

    for path in files:
        try:
            relative = path.relative_to(ROOT)
        except ValueError:
            errors.append(f"path escapes repository: {path}")
            continue
        if path.is_symlink():
            target = path.resolve()
            try:
                target.relative_to(ROOT.resolve())
            except ValueError:
                errors.append(f"symlink escapes repository: {relative}")
        if not path.is_file():
            continue
        size = path.stat().st_size
        if size > MAX_FILE_BYTES:
            errors.append(f"file exceeds {MAX_FILE_BYTES} bytes: {relative} ({size})")
        if path.suffix.lower() in DENIED_SUFFIXES:
            errors.append(f"disallowed binary/archive suffix: {relative}")
        if path.suffix.lower() not in TEXT_SUFFIXES and path.name not in {"LICENSE", "NOTICE"}:
            errors.append(f"unreviewed file type: {relative}")
            continue
        try:
            raw = path.read_bytes()
        except OSError as error:
            errors.append(f"cannot read {relative}: {error}")
            continue
        if b"\0" in raw[:8192]:
            errors.append(f"binary data found in text review path: {relative}")
            continue
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError as error:
            errors.append(f"not valid UTF-8: {relative}: {error}")
            continue
        if "\r" in text:
            errors.append(f"CR line ending found: {relative}")
        if windows_absolute.search(text):
            errors.append(f"Windows absolute path found: {relative}")
        if any(prefix in text for prefix in private_unix_roots):
            errors.append(f"private host path found: {relative}")
        if github_token.search(text):
            errors.append(f"possible GitHub token found: {relative}")
        if private_key in text:
            errors.append(f"private key material found: {relative}")
        if device_id in text:
            errors.append(f"known local device identifier found: {relative}")
        if placeholder_author in text:
            errors.append(f"placeholder author remains: {relative}")

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"Repository privacy and file checks passed ({len(files)} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
