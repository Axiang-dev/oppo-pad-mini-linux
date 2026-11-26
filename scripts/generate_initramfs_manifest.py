#!/usr/bin/env python3
"""Generate a kernel gen_init_cpio manifest from a staging directory."""
from __future__ import annotations

import argparse
import os
from pathlib import Path


def quoted_path(path: Path) -> str:
    text = path.as_posix()
    if any(character.isspace() for character in text):
        raise ValueError(f"manifest paths cannot contain whitespace: {text}")
    return text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"staging root is not a directory: {root}")

    lines: list[str] = [
        "dir /bin 0755 0 0",
        "dir /dev 0755 0 0",
        "dir /proc 0755 0 0",
        "dir /run 0755 0 0",
        "dir /sys 0755 0 0",
        "dir /modules 0755 0 0",
        "nod /dev/console 0600 0 0 c 5 1",
        "nod /dev/kmsg 0600 0 0 c 1 11",
        "nod /dev/null 0666 0 0 c 1 3",
    ]

    for current, directories, files in os.walk(root, followlinks=False):
        directories.sort()
        files.sort()
        current_path = Path(current)
        relative_dir = current_path.relative_to(root)
        if relative_dir == Path("."):
            directories[:] = [name for name in directories if name != "dev"]
            continue

        destination = "/" + relative_dir.as_posix()
        lines.append(f"dir {quoted_path(Path(destination))} 0755 0 0")

        for name in files:
            source = current_path / name
            target = destination + "/" + name
            if source.is_symlink():
                link_target = os.readlink(source)
                lines.append(f"slink {quoted_path(Path(target))} {link_target} 0777 0 0")
            elif source.is_file():
                mode = "0755" if os.access(source, os.X_OK) else "0644"
                lines.append(
                    f"file {quoted_path(Path(target))} "
                    f"{quoted_path(source)} {mode} 0 0"
                )
            else:
                raise ValueError(f"unsupported staging entry: {source}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {args.output} with {len(lines)} entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
