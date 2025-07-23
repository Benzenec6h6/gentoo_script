#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00_env.sh"

swapoff ${DISK}2 || true
umount -R $MOUNTPOINT || true

echo "[✓] Gentoo installation completed. You may now reboot."