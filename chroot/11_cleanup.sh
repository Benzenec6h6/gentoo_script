#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

swapoff ${DISK}2 || true
umount -R $MOUNTPOINT || true

echo "[✓] Gentoo installation completed. You may now reboot."