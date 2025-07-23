#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[+] Formatting partitions and mounting..."

mkfs.ext4 -L root "${TARGET_DISK}3"
mount "${TARGET_DISK}3" "$MOUNTPOINT"

mkswap "${TARGET_DISK}2"
swapon "${TARGET_DISK}2"

if [[ -d /sys/firmware/efi ]]; then
  mkfs.fat -F32 "${TARGET_DISK}1"
  mkdir -p "$MOUNTPOINT/boot"
  mount "${TARGET_DISK}1" "$MOUNTPOINT/boot"
else
  mkdir -p "$MOUNTPOINT/boot"
fi
