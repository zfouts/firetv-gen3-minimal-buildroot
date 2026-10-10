#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 firetv-gen3-minimal-buildroot contributors
# Assemble a bootable USB image for the gazelle Buildroot beachhead.
# RUN ON A LINUX HOST (needs mkimage, mkfs.vfat, mcopy, parted).
#
#   make-boot-image.sh <kernel.img> <dtb.img> <aml_autoscript> <cfgload.txt> <out.img>
#
# Produces an MBR disk image with one FAT32 partition (label GAZLBOOT) at 1 MiB
# containing: kernel.img, dtb.img, cfgload (mkimage-wrapped), aml_autoscript.
# Boot it on the Cube with: adb shell reboot rescueparty
set -euo pipefail

KERNEL="${1:?kernel.img}"; DTB="${2:?dtb.img}"; AML="${3:?aml_autoscript}"
CFGTXT="${4:?cfgload.txt}"; OUT="${5:?out.img}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v mkimage >/dev/null && command -v mkfs.vfat >/dev/null && command -v mcopy >/dev/null && command -v parted >/dev/null || {
  echo ">> installing image tools"; sudo apt-get install -y -qq u-boot-tools dosfstools mtools parted
}

echo ">> wrapping cfgload"
mkimage -A arm64 -O linux -T script -C none -n "gazelle cfgload" -d "$CFGTXT" "$WORK/cfgload" >/dev/null

# FAT partition sized to hold kernel.img (+slack); round up to 96 MiB
FAT_MB=96
echo ">> building FAT ($FAT_MB MiB) with boot files"
dd if=/dev/zero of="$WORK/fat.img" bs=1M count=$FAT_MB status=none
mkfs.vfat -F 32 -n GAZLBOOT "$WORK/fat.img" >/dev/null
mcopy -i "$WORK/fat.img" "$KERNEL" ::kernel.img
mcopy -i "$WORK/fat.img" "$DTB"    ::dtb.img
mcopy -i "$WORK/fat.img" "$WORK/cfgload" ::cfgload
mcopy -i "$WORK/fat.img" "$AML"    ::aml_autoscript
echo ">> FAT contents:"; mdir -i "$WORK/fat.img" ::

# MBR disk: 1 MiB offset + FAT partition
echo ">> building MBR disk image -> $OUT"
PART_START_MB=1
DISK_MB=$((PART_START_MB + FAT_MB + 1))
dd if=/dev/zero of="$OUT" bs=1M count=$DISK_MB status=none
parted -s "$OUT" mklabel msdos
parted -s "$OUT" mkpart primary fat32 ${PART_START_MB}MiB $((PART_START_MB + FAT_MB))MiB
parted -s "$OUT" set 1 boot on
dd if="$WORK/fat.img" of="$OUT" bs=1M seek=$PART_START_MB conv=notrunc status=none

echo ">> DONE: $OUT ($(du -h "$OUT" | cut -f1))"
echo "   flash: gunzip? no - dd this directly:  sudo dd if=$(basename "$OUT") of=/dev/rdiskN bs=4m"
