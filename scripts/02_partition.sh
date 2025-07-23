#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[+] Creating partitions on $TARGET_DISK"

maybe_ignore() {
  "$@" || echo "[!] Ignored error from: $*"
}

maybe_ignore sgdisk --zap-all "$TARGET_DISK"

if [[ -d /sys/firmware/efi ]]; then
  sgdisk -n1:0:+512M -t1:ef00 -c1:"EFI" "$TARGET_DISK"
else
  sgdisk -n1:0:+1M   -t1:ef02 -c1:"BIOS" "$TARGET_DISK"
fi

sgdisk -n2:0:+4G  -t2:8200 -c2:"swap" "$TARGET_DISK"
sgdisk -n3:0:0    -t3:8300 -c3:"root" "$TARGET_DISK"
