#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[+] Formatting partitions and mounting..."

mkfs.ext4 -L root "${DISK_ROOT}"
mount "${DISK_ROOT}" "$MOUNTPOINT"

mkswap "${DISK_SWAP}"
swapon "${DISK_SWAP}"

if [[ -d /sys/firmware/efi ]]; then
  mkfs.fat -F32 "${DISK_BOOT}"
  mkdir -p "$MOUNTPOINT/boot/efi"
  mount "${DISK_BOOT}" "$MOUNTPOINT/boot/efi"
else
  mkdir -p "$MOUNTPOINT/boot"
fi
