#!/usr/bin/env bash
set -e

echo -e "\n#------------------------------------------#"
echo -e "# STEP 3: CONFIGURE SYSTEM & USER ACCOUNTS #"
echo -e "#------------------------------------------#"

if [[ -z "$ROOTFS_DIR" || -z "$BASE_DIR" ]]; then
  echo "E: Build environment variables missing." >&2
  exit 1
fi

echo "[flexOS] Applying overlay files..."
if [[ -d "$BASE_DIR/overlay" ]]; then
  cp -a "$BASE_DIR/overlay/." "$ROOTFS_DIR/"
fi

echo "[flexOS] Setting up single root account without password..."

chroot "$ROOTFS_DIR" /bin/bash -c "
  set -e

  # Remove root password
  passwd -d root

  # Enable core services
  systemctl enable NetworkManager

  # Clean package cache
  apt-get clean
  rm -rf /var/lib/apt/lists/*
"
