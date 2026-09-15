#!/usr/bin/env bash
set -e

echo -e "\n#------------------------------------------#"
echo -e "# STEP 5: PACK IMMUTABLE SQUASHFS IMAGE    #"
echo -e "#------------------------------------------#"

if [[ -z "$WORK_DIR" || -z "$ROOTFS_DIR" ]]; then
  echo "E: Build environment variables missing." >&2
  exit 1
fi

ISO_STAGING="$WORK_DIR/iso_staging/LiveOS"
mkdir -p "$ISO_STAGING"

echo "[flexOS] Packing rootfs into SquashFS (zstd)..."
rm -f "$ISO_STAGING/squashfs.img"

mksquashfs "$ROOTFS_DIR" "$ISO_STAGING/squashfs.img" \
  -comp zstd \
  -b 1048576 \
  -noappend \
  -e boot/vmlinuz* boot/initrd*

echo "[flexOS] SquashFS created at $ISO_STAGING/squashfs.img"
