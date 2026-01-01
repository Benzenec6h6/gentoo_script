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

echo "[*] Collecting PARTUUIDs"

ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$DISK_ROOT")
SWAP_PARTUUID=$(blkid -s PARTUUID -o value "$DISK_SWAP")
EFI_PARTUUID=$(blkid -s PARTUUID -o value "$DISK_BOOT")

sed -i "/^export ROOT_PARTUUID=/d" "$SCRIPT_DIR/00_env.sh"
sed -i "/^export SWAP_PARTUUID=/d" "$SCRIPT_DIR/00_env.sh"
sed -i "/^export EFI_PARTUUID=/d"  "$SCRIPT_DIR/00_env.sh"

cat >> "$SCRIPT_DIR/00_env.sh" <<EOF
export ROOT_PARTUUID="$ROOT_PARTUUID"
export SWAP_PARTUUID="$SWAP_PARTUUID"
export EFI_PARTUUID="$EFI_PARTUUID"
EOF

echo "→ root=$ROOT_PARTUUID"
echo "→ swap=$SWAP_PARTUUID"
echo "→ efi =$EFI_PARTUUID"
