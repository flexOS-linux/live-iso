#!/usr/bin/env bash
set -e

echo -e "\n#------------------------------------------#"
echo -e "# STEP 2: INJECT UPSTREAM LINUX FIRMWARE   #"
echo -e "#------------------------------------------#"

if [[ -z "$BASE_DIR" || -z "$ROOTFS_DIR" ]]; then
  echo "E: Build environment variables missing." >&2
  exit 1
fi

CACHE_DIR="$BASE_DIR/cache"
FIRMWARE_CACHE="$CACHE_DIR/linux-firmware"

mkdir -p "$CACHE_DIR"

if [[ -d "$FIRMWARE_CACHE/.git" ]]; then
  echo "[flexOS] Updating existing linux-firmware cache..."
  git -C "$FIRMWARE_CACHE" pull --rebase || true
else
  echo "[flexOS] Cloning linux-firmware for the first time (this will take a while)..."
  git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git "$FIRMWARE_CACHE"
fi

echo "[flexOS] Copying firmware binaries into rootfs..."
mkdir -p "$ROOTFS_DIR/lib/firmware"
cp -a "$FIRMWARE_CACHE"/. "$ROOTFS_DIR/lib/firmware/"

# Remove only the git metadata inside rootfs, keeping local cache intact
rm -rf "$ROOTFS_DIR/lib/firmware/.git"
