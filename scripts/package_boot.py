#!/usr/bin/env python3
"""Package an OPD2515 diagnostic Image into the tested boot_b image layout.

The input stock image is used as the structural shell. The script retains the
stock boot header, kernel command line, and AVB descriptor layout, places the
diagnostic Image and DTB in the kernel region, and recreates the verified
unlocked-device AVB hash descriptor.

This script does not authorize a partition write.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import sys

EXPECTED_PARTITION_SIZE = 0x6000000
HEADER_SIZE = 4096
VBMETA_SIZE = 768
AVB_FOOTER_SIZE = 64
DTB_MAGIC = b"\xd0\x0d\xfe\xed"


def read_be32(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def read_be64(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from(">Q", data, offset)[0]


def read_le32(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def put_be64(data: bytearray, offset: int, value: int) -> None:
    struct.pack_into(">Q", data, offset, value)


def put_le32(data: bytearray, offset: int, value: int) -> None:
    struct.pack_into("<I", data, offset, value)


def require_range(data: bytes | bytearray, offset: int, size: int, label: str) -> None:
    if offset < 0 or size < 0 or offset + size > len(data):
        raise ValueError(f"{label} lies outside the image")


def build_image(stock: bytes, kernel: bytes, dtb: bytes) -> tuple[bytes, dict]:
    if stock[:8] != b"ANDROID!":
        raise ValueError("stock image does not contain the Android boot magic")
    if len(stock) != EXPECTED_PARTITION_SIZE:
        raise ValueError(
            f"unexpected boot partition size: {len(stock)} != {EXPECTED_PARTITION_SIZE}"
        )
    if read_le32(stock, 40) != 4 or read_le32(stock, 20) != 1584:
        raise ValueError("stock image is not Android boot image v4 with header size 1584")
    if read_le32(stock, 12) != 0:
        raise ValueError("stock image has an external ramdisk")
    if read_le32(stock, 1580) != 0:
        raise ValueError("stock image unexpectedly contains a boot signature")
    if kernel[:4] == b"\x7fELF":
        raise ValueError("kernel must be an ARM64 Image, not an ELF file")
    if dtb[:4] != DTB_MAGIC:
        raise ValueError("device tree does not contain an FDT magic")

    kernel_contains_dtb = kernel.find(dtb) >= 0
    payload = kernel if kernel_contains_dtb else kernel + dtb
    if HEADER_SIZE + len(payload) + VBMETA_SIZE + AVB_FOOTER_SIZE > len(stock):
        raise ValueError("kernel, DTB, and AVB data exceed the stock partition shell")

    footer_offset = len(stock) - AVB_FOOTER_SIZE
    footer = stock[footer_offset:]
    if footer[:4] != b"AVBf":
        raise ValueError("stock image is missing the AVB footer")
    _, stock_vb_offset, stock_vb_size = struct.unpack_from(">QQQ", footer, 12)
    require_range(stock, stock_vb_offset, stock_vb_size, "stock vbmeta")
    stock_vbmeta = stock[stock_vb_offset : stock_vb_offset + stock_vb_size]
    if stock_vbmeta[:4] != b"AVB0":
        raise ValueError("stock vbmeta magic is missing")

    auth_size = read_be64(stock_vbmeta, 12)
    aux_size = read_be64(stock_vbmeta, 20)
    descriptor_offset = read_be64(stock_vbmeta, 96)
    descriptor_size = read_be64(stock_vbmeta, 104)
    descriptor_start = 256 + auth_size + descriptor_offset
    require_range(stock_vbmeta, descriptor_start, descriptor_size, "AVB descriptor")
    descriptor = stock_vbmeta[descriptor_start : descriptor_start + descriptor_size]
    if len(descriptor) < 480 or read_be64(descriptor, 0) != 2:
        raise ValueError("stock AVB hash descriptor is not the expected type")

    body = descriptor[16:]
    name_size = read_be32(body, 40)
    salt_size = read_be32(body, 44)
    digest_size = read_be32(body, 48)
    variable_offset = 116
    name = body[variable_offset : variable_offset + name_size].rstrip(b"\x00")
    salt = body[
        variable_offset + name_size : variable_offset + name_size + salt_size
    ]
    if name != b"boot" or salt_size != 16 or digest_size != 32:
        raise ValueError("stock AVB descriptor does not describe a 16-byte-salt boot image")

    image = bytearray(len(stock))
    image[:HEADER_SIZE] = stock[:HEADER_SIZE]
    put_le32(image, 8, len(payload))
    image[HEADER_SIZE : HEADER_SIZE + len(payload)] = payload

    original_size = (HEADER_SIZE + len(payload) + 4095) & ~4095
    if original_size + VBMETA_SIZE > footer_offset:
        raise ValueError("vbmeta does not fit before the AVB footer")

    vbmeta = bytearray(VBMETA_SIZE)
    vbmeta[:256] = stock_vbmeta[:256]
    vbmeta[0:4] = b"AVB0"
    struct.pack_into(">II", vbmeta, 4, 1, 0)
    put_be64(vbmeta, 12, 0)
    put_be64(vbmeta, 20, 512)
    struct.pack_into(">I", vbmeta, 28, 0)
    for offset in (32, 40, 48, 56, 64, 72, 80, 88):
        put_be64(vbmeta, offset, 0)
    put_be64(vbmeta, 64, 480)
    put_be64(vbmeta, 80, 480)
    put_be64(vbmeta, 96, 0)
    put_be64(vbmeta, 104, 480)
    vbmeta[128:176] = stock_vbmeta[128:176]

    new_descriptor = bytearray(descriptor)
    put_be64(new_descriptor, 16, original_size)
    digest_offset = 16 + variable_offset + name_size + salt_size
    new_descriptor[digest_offset : digest_offset + 32] = b"\x00" * 32
    vbmeta[256 : 256 + 480] = new_descriptor

    image[original_size : original_size + VBMETA_SIZE] = vbmeta
    digest = hashlib.sha256(salt + bytes(image[:original_size])).digest()
    image_digest_offset = (
        original_size + 256 + 16 + variable_offset + name_size + salt_size
    )
    image[image_digest_offset : image_digest_offset + 32] = digest

    new_footer = bytearray(AVB_FOOTER_SIZE)
    new_footer[:4] = b"AVBf"
    struct.pack_into(">II", new_footer, 4, 1, 0)
    struct.pack_into(
        ">QQQ", new_footer, 12, original_size, original_size, VBMETA_SIZE
    )
    image[footer_offset:] = new_footer

    report = {
        "partition_bytes": len(image),
        "payload_bytes": len(payload),
        "kernel_contains_dtb": kernel_contains_dtb,
        "original_size": original_size,
        "sha256": hashlib.sha256(image).hexdigest(),
        "avb": {
            "algorithm": "NONE",
            "salt": salt.hex(),
            "digest": digest.hex(),
            "vbmeta_offset": original_size,
            "vbmeta_size": VBMETA_SIZE,
        },
        "header_version": read_le32(image, 40),
        "external_ramdisk_bytes": read_le32(image, 12),
    }
    return bytes(image), report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stock", required=True, type=Path)
    parser.add_argument("--kernel", required=True, type=Path)
    parser.add_argument("--dtb", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    for label, path in (("stock", args.stock), ("kernel", args.kernel), ("dtb", args.dtb)):
        if not path.is_file():
            parser.error(f"{label} file not found: {path}")
    if args.out.exists() and not args.force:
        parser.error(f"output exists: {args.out} (use --force to replace it)")

    image, report = build_image(
        args.stock.read_bytes(), args.kernel.read_bytes(), args.dtb.read_bytes()
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.out.with_name(args.out.name + ".tmp")
    temporary.write_bytes(image)
    os.replace(temporary, args.out)

    report.update(
        {
            "stock": str(args.stock),
            "kernel": str(args.kernel),
            "dtb": str(args.dtb),
            "out": str(args.out),
        }
    )
    report_path = args.out.with_suffix(".json")
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
