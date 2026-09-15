#!/usr/bin/env bash
set -e

# Ensure root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: flexOS build system requires root permissions." >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-config/build.conf}"

# Load configuration
if [[ -f "$BASE_DIR/$CONFIG_FILE" ]]; then
  echo "[flexOS] Loading config: $CONFIG_FILE"
  source "$BASE_DIR/$CONFIG_FILE"
else
  echo "E: Configuration file $CONFIG_FILE not found!" >&2
  exit 1
fi

# Define build paths
WORK_DIR="$BASE_DIR/work/$ARCH"
ROOTFS_DIR="$WORK_DIR/rootfs"
BUILD_DIR="$BASE_DIR/build"

export BASE_DIR WORK_DIR ROOTFS_DIR BUILD_DIR ARCH DEBIAN_SUITE DEBIAN_MIRROR KERNEL_URL KERNEL_VERSION

echo "=========================================="
echo "  Building $DISTRO_NAME ($VERSION-$RELEASE_CHANNEL) [$ARCH]"
echo "=========================================="

# Cleanup previous workspace
mkdir -p "$WORK_DIR" "$BUILD_DIR"

# Step 1: Bootstrap
bash "$BASE_DIR/scripts/01-bootstrap.sh"

# Step 2: Firmware
bash "$BASE_DIR/scripts/02-firmware.sh"

# Step 3: Finalize
bash "$BASE_DIR/scripts/03-finalize.sh"

# Step 4: Kernel
bash "$BASE_DIR/scripts/04-kernel.sh"

# Step 5: SquashFS
bash "$BASE_DIR/scripts/05-squashfs.sh"

# Step 6: ISO
bash "$BASE_DIR/scripts/06-iso.sh"

echo "=== [flexOS] Packaging ISO Artifacts ==="
YYYYMMDD="$(date +%Y%m%d)"
ISO_NAME="${DISTRO_NAME}-${VERSION}-${RELEASE_CHANNEL}-${ARCH}-${YYYYMMDD}.iso"
OUTPUT_ISO="$BUILD_DIR/$ISO_NAME"

mv "$WORK_DIR/live.iso" "$OUTPUT_ISO"

echo "=== [flexOS] Generating SHA256 checksum ==="
cd "$BUILD_DIR"
sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256"
cd "$BASE_DIR"

echo "=========================================="
echo " Build finished successfully!"
echo " Output path: $BUILD_DIR"
echo "=========================================="
