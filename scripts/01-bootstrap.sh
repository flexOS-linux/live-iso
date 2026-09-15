#!/usr/bin/env bash
set -e

echo -e "\n#------------------------------------------#"
echo -e "# STEP 1: DEBOOTSTRAP BASE ROOTFS          #"
echo -e "#------------------------------------------#"

if [[ -z "$ROOTFS_DIR" || -z "$BASE_DIR" ]]; then
  echo "E: Build environment variables missing." >&2
  exit 1
fi

CACHE_DIR="$BASE_DIR/cache/debootstrap"
mkdir -p "$CACHE_DIR"

echo "[flexOS] Cleaning up previous rootfs target..."
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

echo "[flexOS] Running debootstrap for suite '$DEBIAN_SUITE' ($ARCH) with local cache..."
debootstrap \
  --arch="$ARCH" \
  --variant=minbase \
  --cache-dir="$CACHE_DIR" \
  --include=systemd-sysv,dbus,network-manager,sudo,bash-completion,zstd,curl,ca-certificates,git \
  "$DEBIAN_SUITE" \
  "$ROOTFS_DIR" \
  "$DEBIAN_MIRROR"
