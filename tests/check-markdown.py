#!/usr/bin/env python3
"""Validate repository Markdown encoding, fences, and local links."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parent.parent
MARKDOWN_FILES = sorted(ROOT.rglob("*.md"))
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#")
LINK_TARGET_RE = re.compile(r"^(?:<([^>]+)>|([^\s]+))")


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def check_file(path: Path) -> None:
    try:
        raw = path.read_bytes()
    except OSError as error:
        fail(f"cannot read {path.relative_to(ROOT)}: {error}")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as error:
        fail(f"{path.relative_to(ROOT)} is not valid UTF-8: {error}")
    if b"\r" in raw:
        fail(f"{path.relative_to(ROOT)} contains CR line endings")
    if "\x00" in text:
        fail(f"{path.relative_to(ROOT)} contains NUL bytes")

    fence_open = False
    for number, line in enumerate(text.splitlines(), 1):
        if line.startswith("```"):
            fence_open = not fence_open
    if fence_open:
        fail(f"{path.relative_to(ROOT)} has an unclosed code fence")

    for match in LINK_RE.finditer(text):
        destination = match.group(1).strip()
        if not destination or destination.startswith(SKIP_PREFIXES):
            continue
        target_match = LINK_TARGET_RE.match(destination)
        if not target_match:
            continue
        target = target_match.group(1) or target_match.group(2)
        target = unquote(target.split("#", 1)[0])
        if not target:
            continue
        if Path(target).is_absolute():
            fail(f"{path.relative_to(ROOT)} uses an absolute link target: {target}")
        resolved = (path.parent / target).resolve()
        try:
            resolved.relative_to(ROOT)
        except ValueError:
            fail(f"{path.relative_to(ROOT)} link escapes the repository: {target}")
        if not resolved.exists():
            fail(f"{path.relative_to(ROOT)} links to missing path: {target}")


for markdown in MARKDOWN_FILES:
    check_file(markdown)

print(f"Markdown checks passed ({len(MARKDOWN_FILES)} files)")
