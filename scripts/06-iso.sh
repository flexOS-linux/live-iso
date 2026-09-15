#!/usr/bin/env bash
set -e

echo -e "\n#------------------------------------------#"
echo -e "# STEP 6: GENERATE BOOTABLE ISO           #"
echo -e "#------------------------------------------#"

if [[ -z "$WORK_DIR" || -z "$ROOTFS_DIR" || -z "$BASE_DIR" ]]; then
  echo "E: Build environment variables missing." >&2
  exit 1
fi

ISO_STAGING="$WORK_DIR/iso_staging"
LIVE_DIR="$ISO_STAGING/live"
GRUB_DIR="$ISO_STAGING/boot/grub"
LIVE_OS_DIR="$ISO_STAGING/LiveOS"

mkdir -p "$LIVE_DIR" "$GRUB_DIR" "$LIVE_OS_DIR"

echo "[flexOS] Copying Kernel and Initrd to ISO staging..."
KERNEL_FILE=$(ls -1 "$ROOTFS_DIR"/boot/vmlinuz-* 2>/dev/null | head -n 1 || true)
INITRD_FILE=$(ls -1 "$ROOTFS_DIR"/boot/initrd.img-* 2>/dev/null | head -n 1 || true)

if [[ -z "$KERNEL_FILE" || -z "$INITRD_FILE" ]]; then
  echo "E: Kernel or Initrd missing in $ROOTFS_DIR/boot!" >&2
  exit 1
fi

cp "$KERNEL_FILE" "$LIVE_DIR/vmlinuz"
cp "$INITRD_FILE" "$LIVE_DIR/initrd.img"

echo "[flexOS] Applying GRUB configuration..."
if [[ -f "$BASE_DIR/config/grub.cfg" ]]; then
  cp "$BASE_DIR/config/grub.cfg" "$GRUB_DIR/grub.cfg"
else
  echo "E: $BASE_DIR/config/grub.cfg not found!" >&2
  exit 1
fi

echo "[flexOS] Building ISO image via xorriso/grub..."
grub2-mkrescue -o "$WORK_DIR/live.iso" "$ISO_STAGING" -- -volid "FLEXOS_LIVE"

echo "[flexOS] ISO successfully compiled at: $WORK_DIR/live.iso"
