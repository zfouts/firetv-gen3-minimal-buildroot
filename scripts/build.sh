#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 firetv-gen3-minimal-buildroot contributors
# Build the minimal gazelle image end-to-end on an x86_64 Linux host.
#
#   # optional: bake in an SSH key for root (otherwise password auth, user root)
#   export GAZELLE_SSH_PUBKEY="ssh-ed25519 AAAA... you@host"
#   ./scripts/build.sh
#
# Produces out/firetv-gen3-minimal.img (dd to a USB stick; see scripts/flash.sh).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BR_VER="${BR_VER:-2026.02.3}"
BR_DIR="$REPO/.buildroot/buildroot-$BR_VER"
EXT="$REPO/buildroot-gazelle"
OUT="$REPO/output"
INPUTS="$REPO/inputs"
IMG_OUT="$REPO/out"

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  echo "WARNING: Buildroot is only supported on x86_64 Linux. You are on $(uname -s)/$(uname -m)."
  echo "         Use an x86_64 Linux host (or a Docker container) to build."
fi

for f in kernel_Image dtb.img aml_autoscript; do
  [ -f "$INPUTS/$f" ] || { echo "ERROR: missing inputs/$f"; echo "See inputs/README.md - harvest these from a CoreELEC gazelle image first."; exit 1; }
done

mkdir -p "$REPO/.buildroot" "$IMG_OUT"
if [ ! -d "$BR_DIR" ]; then
  echo ">> downloading Buildroot $BR_VER"
  curl -fsSL "https://buildroot.org/downloads/buildroot-$BR_VER.tar.xz" -o "$REPO/.buildroot/br.tar.xz"
  tar -C "$REPO/.buildroot" -xf "$REPO/.buildroot/br.tar.xz"
  rm -f "$REPO/.buildroot/br.tar.xz"
fi

echo ">> configuring (gazelle_defconfig)"
make -C "$BR_DIR" BR2_EXTERNAL="$EXT" O="$OUT" gazelle_defconfig

echo ">> building rootfs (first run compiles a cross-toolchain; can take a while)"
make -C "$BR_DIR" O="$OUT"

echo ">> repacking kernel.img (vendor Image + Buildroot initramfs)"
python3 "$REPO/boot-glue/mkbootimg_v0.py" \
  --kernel  "$INPUTS/kernel_Image" \
  --ramdisk "$OUT/images/rootfs.cpio.zst" \
  --out     "$IMG_OUT/kernel.img"

echo ">> assembling USB image"
"$REPO/boot-glue/make-boot-image.sh" \
  "$IMG_OUT/kernel.img" "$INPUTS/dtb.img" "$INPUTS/aml_autoscript" \
  "$REPO/boot-glue/cfgload.txt" "$IMG_OUT/firetv-gen3-minimal.img"

echo
echo ">> DONE: $IMG_OUT/firetv-gen3-minimal.img"
echo "   Flash with: ./scripts/flash.sh   (or dd it to your USB stick)"
