#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 firetv-gen3-minimal-buildroot contributors
# Flash the built image to a USB stick. Works on macOS and Linux.
# Usage:  ./scripts/flash.sh [/dev/diskN|/dev/sdX] [image]
# Auto-detects a single external/removable USB; always confirms before writing.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
IMG=""
DISK=""
for a in "$@"; do
  case "$a" in
    /dev/*) DISK="$a";;
    *) IMG="$a";;
  esac
done
IMG="${IMG:-$REPO/out/firetv-gen3-minimal.img}"
[ -f "$IMG" ] || { echo "ERROR: image not found: $IMG"; exit 1; }

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  if [ -z "$DISK" ]; then
    disks=$(diskutil list external physical 2>/dev/null | awk '/^\/dev\/disk/{print $1}')
    n=$(printf '%s\n' "$disks" | grep -c '/dev/disk' || true)
    [ "$n" -eq 1 ] || { echo "Found $n external disks; pass one explicitly:"; printf '%s\n' $disks; exit 1; }
    DISK=$(printf '%s\n' "$disks" | head -1)
  fi
  diskutil info "$DISK" | grep -iE 'Device Node|Media Name|Disk Size|Removable|Protocol' || true
  printf '!! ERASES %s. Type %s to confirm: ' "$DISK" "${DISK##*/}"; read -r ans
  [ "$ans" = "${DISK##*/}" ] || { echo aborted; exit 1; }
  diskutil unmountDisk "$DISK"
  sudo dd if="$IMG" of="${DISK/disk/rdisk}" bs=4m
  sync; diskutil eject "$DISK" || true
else  # Linux
  if [ -z "$DISK" ]; then
    echo "Pass the target explicitly on Linux, e.g. ./scripts/flash.sh /dev/sdX"
    lsblk -dn -o NAME,SIZE,TRAN,RM,MODEL | awk '$3=="usb"||$4=="1"{print "  /dev/"$0}'
    exit 1
  fi
  lsblk "$DISK" || true
  printf '!! ERASES %s. Type %s to confirm: ' "$DISK" "$(basename "$DISK")"; read -r ans
  [ "$ans" = "$(basename "$DISK")" ] || { echo aborted; exit 1; }
  for p in "$DISK"*[0-9]; do sudo umount "$p" 2>/dev/null || true; done
  sudo dd if="$IMG" of="$DISK" bs=4M conv=fsync status=progress
  sync
fi
echo ">> DONE - put the stick in the Cube and boot USB (adb shell reboot rescueparty)."
