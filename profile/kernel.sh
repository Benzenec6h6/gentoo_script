#!/bin/bash
set -euo pipefail

emerge --quiet sys-kernel/gentoo-sources

cd /usr/src/linux

if [[ -f /profile/kernel.config ]]; then
  echo ">>> Applying custom kernel config"
  cp /profile/kernel.config .config
else
  echo ">>> Using defconfig"
  make defconfig
fi

make -j$(nproc)
make modules_install
make install
