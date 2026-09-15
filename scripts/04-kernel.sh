#!/usr/bin/env bash
set -e

echo -e "\n#------------------------------------------#"
echo -e "# STEP 4: BUILD LINUX KERNEL               #"
echo -e "#------------------------------------------#"

if [[ -z "$ROOTFS_DIR" || -z "$BASE_DIR" || -z "$WORK_DIR" ]]; then
  echo "E: Build environment variables missing." >&2
  exit 1
fi

SRC_DIR="$BASE_DIR/cache/linux-src"
CONFIG_FILE="$BASE_DIR/config/kernel.config"

# Map Debian arch to Kernel ARCH format
case "$ARCH" in
  amd64) KBUILD_ARCH="x86" ;;
  arm64) KBUILD_ARCH="arm64" ;;
  *)     KBUILD_ARCH="$ARCH" ;;
esac

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "E: Kernel config file not found at $CONFIG_FILE!" >&2
  exit 1
fi

mkdir -p "$BASE_DIR/cache"

if [[ -n "$KERNEL_VERSION" ]]; then
  if [[ "$KERNEL_VERSION" != v* ]]; then
    KERNEL_TAG="v$KERNEL_VERSION"
  else
    KERNEL_TAG="$KERNEL_VERSION"
  fi
fi

# Fetch kernel source code if not cached
if [[ -d "$SRC_DIR/.git" ]]; then
  echo "[flexOS] Using cached Linux kernel source repository..."
  git -C "$SRC_DIR" fetch --tags
else
  echo "[flexOS] Cloning Linux kernel sources (${KERNEL_TAG:-master})..."
  BRANCH_OPT=""
  if [[ -n "$KERNEL_TAG" ]]; then
    BRANCH_OPT="--branch $KERNEL_TAG"
  fi
  git clone --depth 1 $BRANCH_OPT "${KERNEL_URL:-https://github.com/torvalds/linux.git}" "$SRC_DIR"
fi

if [[ -n "$KERNEL_TAG" ]]; then
  echo "[flexOS] Checking out specific kernel version: $KERNEL_TAG"
  git -C "$SRC_DIR" checkout "$KERNEL_TAG"
fi

# Prepare configuration
echo "[flexOS] Generating base x86_64_defconfig..."
make -C "$SRC_DIR" ARCH="$KBUILD_ARCH" x86_64_defconfig

echo "[flexOS] Merging custom $CONFIG_FILE over defconfig..."
(cd "$SRC_DIR" && ./scripts/kconfig/merge_config.sh -m .config "$CONFIG_FILE")

echo "[flexOS] Resolving dependencies..."
make -C "$SRC_DIR" ARCH="$KBUILD_ARCH" olddefconfig

# Compile Kernel and Modules
echo "[flexOS] Compiling kernel bzImage and modules with $(nproc) threads (ARCH=$KBUILD_ARCH)..."
make -C "$SRC_DIR" ARCH="$KBUILD_ARCH" olddefconfig
make -C "$SRC_DIR" ARCH="$KBUILD_ARCH" -j"$(nproc)" bzImage modules

# Install modules and binary into rootfs
echo "[flexOS] Installing kernel modules into rootfs..."
make -C "$SRC_DIR" ARCH="$KBUILD_ARCH" modules_install INSTALL_MOD_PATH="$ROOTFS_DIR"

echo "[flexOS] Copying vmlinuz to rootfs /boot..."
KERNEL_RELEASE=$(make -s -C "$SRC_DIR" ARCH="$KBUILD_ARCH" kernelrelease)
mkdir -p "$ROOTFS_DIR/boot"
cp "$SRC_DIR/arch/x86/boot/bzImage" "$ROOTFS_DIR/boot/vmlinuz-$KERNEL_RELEASE"

# Generate Initramfs with dracut inside chroot
echo "[flexOS] Generating initramfs via dracut for $KERNEL_RELEASE..."
chroot "$ROOTFS_DIR" /bin/bash -c "
  set -e
  apt-get update
  apt-get install -y --no-install-recommends dracut dracut-live
  dracut --kver '$KERNEL_RELEASE' \
         --no-hostonly \
         --add 'dmsquash-live overlayfs base rescue' \
         --force '/boot/initrd.img-$KERNEL_RELEASE'
  apt-get clean
  rm -rf /var/lib/apt/lists/*
"

echo "[flexOS] Kernel $KERNEL_RELEASE successfully built and installed!"
