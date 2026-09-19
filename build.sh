#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
CONFIG_FILE="${1:-configs/build.conf}"

if [[ -f "$BASE_DIR/$CONFIG_FILE" ]]; then
  echo "[+] Loading config: $CONFIG_FILE"
  source "$BASE_DIR/$CONFIG_FILE"
else
  echo "E: Configuration file $CONFIG_FILE not found!" >&2
  exit 1
fi

WORK_DIR="$BASE_DIR/work"
ROOTFS_DIR="$WORK_DIR/rootfs/image"
BUILD_DIR="$BASE_DIR/builds"
ISO_STAGING="$WORK_DIR/iso_staging"

unshare -r -m rm -rf "$ROOTFS_DIR" "$ISO_STAGING"
mkdir -p "$BUILD_DIR" "$WORK_DIR"

echo "=========================================="
echo "  Building $DISTRO_NAME ($VERSION-$RELEASE_CHANNEL)"
echo "=========================================="

mkosi build

echo "[+] Packing rootfs into SquashFS..."
LIVE_OS_DIR="$ISO_STAGING/LiveOS"
mkdir -p "$LIVE_OS_DIR"

unshare -r -m mksquashfs "$ROOTFS_DIR" "$LIVE_OS_DIR/squashfs.img" \
  -comp zstd \
  -b 1048576 \
  -noappend \
  -e boot/vmlinuz* boot/initrd*

echo "[+] Preparing ISO staging area..."
BOOT_DIR="$ISO_STAGING/boot"
GRUB_DIR="$BOOT_DIR/grub"
mkdir -p "$BOOT_DIR" "$GRUB_DIR"

KERNEL_FILE=$(ls -1 "$WORK_DIR"/rootfs/image.vmlinuz 2>/dev/null | head -n 1 || true)
INITRD_FILE="$ROOTFS_DIR/boot/initrd.img"

if [[ ! -f "$KERNEL_FILE" || ! -f "$INITRD_FILE" ]]; then
echo $KERNEL_FILE
echo $INITRD_FILE
  echo "E: Missing Kernel or Initrd!" >&2
  exit 1
fi

cp "$KERNEL_FILE" "$BOOT_DIR/vmlinuz"
cp "$INITRD_FILE" "$BOOT_DIR/initrd.img"

echo "[+] Applying GRUB configuration..."
if [[ -f "$BASE_DIR/config/grub.cfg" ]]; then
  cp "$BASE_DIR/config/grub.cfg" "$GRUB_DIR/grub.cfg"
elif [[ -f "$BASE_DIR/configs/grub.cfg" ]]; then
  cp "$BASE_DIR/configs/grub.cfg" "$GRUB_DIR/grub.cfg"
else
  echo "E: grub.cfg not found!" >&2
  exit 1
fi

echo "[+] Building ISO image..."
YYYYMMDD="$(date +%Y%m%d)"
ISO_NAME="${DISTRO_NAME}-${VERSION}-${RELEASE_CHANNEL}-${ARCH}-${YYYYMMDD}.iso"
OUTPUT_ISO="$BUILD_DIR/$ISO_NAME"

grub2-mkrescue -o "$OUTPUT_ISO" "$ISO_STAGING" -- -volid "FLEXOS_LIVE"

echo "[+] Generating SHA256 checksum..."
cd "$BUILD_DIR"
sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256"

echo "=========================================="
echo " Build finished successfully!"
echo " Output path: $OUTPUT_ISO"
echo "=========================================="
