#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 firetv-gen3-minimal-buildroot contributors
"""Minimal Android boot image (header v0) packer for gazelle.

Reproduces the layout of the harvested CoreELEC kernel.img:
  kernel_addr=0x02000000 ramdisk_addr=0x01000000 second_addr=0x00f00000
  tags_addr=0x00000100 page_size=2048 header_version=0 cmdline="" (empty)
so that the cfgload/bootm chain sets the kernel cmdline, exactly as stock.

Usage:
  mkbootimg_v0.py --kernel Image --ramdisk rootfs.cpio.gz --out kernel.img
"""
import argparse, struct, hashlib, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kernel", required=True)
    ap.add_argument("--ramdisk", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--kernel_addr", type=lambda x: int(x, 0), default=0x02000000)
    ap.add_argument("--ramdisk_addr", type=lambda x: int(x, 0), default=0x01000000)
    ap.add_argument("--second_addr", type=lambda x: int(x, 0), default=0x00f00000)
    ap.add_argument("--tags_addr", type=lambda x: int(x, 0), default=0x00000100)
    ap.add_argument("--pagesize", type=lambda x: int(x, 0), default=2048)
    ap.add_argument("--cmdline", default="")
    ap.add_argument("--name", default="")
    args = ap.parse_args()

    kernel = open(args.kernel, "rb").read()
    ramdisk = open(args.ramdisk, "rb").read()
    second = b""
    page = args.pagesize

    def pad(data):
        rem = len(data) % page
        return data + (b"\x00" * (page - rem) if rem else b"")

    # SHA1 id over (kernel,ksize,ramdisk,rsize,second,ssize) - mkbootimg v0 behaviour
    sha = hashlib.sha1()
    for blob in (kernel, ramdisk, second):
        sha.update(blob)
        sha.update(struct.pack("<I", len(blob)))
    img_id = sha.digest()[:20] + b"\x00" * 12  # 32-byte id field

    cmdline = args.cmdline.encode()[:512].ljust(512, b"\x00")
    name = args.name.encode()[:16].ljust(16, b"\x00")
    extra = b"\x00" * 1024

    hdr = b"ANDROID!"
    hdr += struct.pack("<10I",
                       len(kernel), args.kernel_addr,
                       len(ramdisk), args.ramdisk_addr,
                       len(second), args.second_addr,
                       args.tags_addr, page,
                       0,            # header_version
                       0)            # os_version
    hdr += name + cmdline + img_id + extra

    out = pad(hdr) + pad(kernel) + pad(ramdisk)
    open(args.out, "wb").write(out)
    print(f"wrote {args.out}: kernel={len(kernel)} ramdisk={len(ramdisk)} "
          f"page={page} total={len(out)} bytes")

if __name__ == "__main__":
    sys.exit(main())
