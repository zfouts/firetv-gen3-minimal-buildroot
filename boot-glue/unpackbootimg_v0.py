#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 firetv-gen3-minimal-buildroot contributors
"""Unpack an Android boot image (header v0) into its kernel Image + ramdisk.

Use this to harvest the raw kernel `Image` from a CoreELEC gazelle `kernel.img`
so it can be repacked with a Buildroot initramfs (see mkbootimg_v0.py).

Usage:
  unpackbootimg_v0.py kernel.img --out-kernel Image --out-ramdisk ramdisk.cpio.zst
"""
import argparse, struct, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--out-kernel", required=True)
    ap.add_argument("--out-ramdisk")
    a = ap.parse_args()

    f = open(a.image, "rb").read()
    if f[:8] != b"ANDROID!":
        sys.exit("not an ANDROID! boot image")
    (ks, ka, rs, ra, ss, sa, tags, page, hv, ov) = struct.unpack("<10I", f[8:48])
    print(f"kernel_size={ks} kernel_addr=0x{ka:08x} ramdisk_size={rs} "
          f"ramdisk_addr=0x{ra:08x} page={page} header_version={hv}")

    def pages(n): return (n + page - 1) // page
    off_k = page
    off_r = off_k + pages(ks) * page
    open(a.out_kernel, "wb").write(f[off_k:off_k + ks])
    print(f"wrote {a.out_kernel} ({ks} bytes)")
    if a.out_ramdisk and rs:
        open(a.out_ramdisk, "wb").write(f[off_r:off_r + rs])
        print(f"wrote {a.out_ramdisk} ({rs} bytes)")

if __name__ == "__main__":
    main()
