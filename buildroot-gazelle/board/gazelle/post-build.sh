#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 firetv-gen3-minimal-buildroot contributors
# Buildroot post-build hook. Runs against the target rootfs ($1 = $TARGET_DIR).
#
# SSH auth is chosen at BUILD TIME via environment variables (nothing secret is
# committed to this repo):
#
#   GAZELLE_SSH_PUBKEY   If set, installed as root's authorized_keys (key auth).
#                        e.g. export GAZELLE_SSH_PUBKEY="ssh-ed25519 AAAA... you@host"
#
# If GAZELLE_SSH_PUBKEY is unset, the image uses PASSWORD auth only, with the root
# password from the defconfig (BR2_TARGET_GENERIC_ROOT_PASSWD, default "gazelle").
# Change that password in configs/gazelle_defconfig for anything beyond first boot.
set -e
TARGET_DIR="$1"

if [ -n "${GAZELLE_SSH_PUBKEY:-}" ]; then
  mkdir -p "$TARGET_DIR/root/.ssh"
  printf '%s\n' "$GAZELLE_SSH_PUBKEY" > "$TARGET_DIR/root/.ssh/authorized_keys"
  chmod 700 "$TARGET_DIR/root/.ssh"
  chmod 600 "$TARGET_DIR/root/.ssh/authorized_keys"
  chmod 700 "$TARGET_DIR/root"
  echo "post-build: installed GAZELLE_SSH_PUBKEY for root (key auth enabled)"
else
  echo "post-build: GAZELLE_SSH_PUBKEY not set -> password auth only (user: root)"
fi
