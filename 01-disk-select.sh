#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

mapfile -t disks < <(lsblk -ndo NAME,SIZE,TYPE | awk '$3=="disk" && $1!~/^loop/ {print $1, $2}')

if ((${#disks[@]}==0)); then
  echo "No block device found"; exit 1
fi

echo "== Select target disk =="
for i in "${!disks[@]}"; do
  printf "%2d) /dev/%s (%s)\n" $((i+1)) \
    "$(awk '{print $1}' <<<"${disks[$i]}")" \
    "$(awk '{print $2}' <<<"${disks[$i]}")"
done

read -rp 'Index: ' idx
((idx >= 1 && idx <= ${#disks[@]})) || { echo "Invalid index"; exit 1; }
TARGET_DISK="/dev/$(awk '{print $1}' <<<"${disks[idx-1]}")"
sed -i "s|^export TARGET_DISK=.*|export TARGET_DISK=\"$TARGET_DISK\"|" ./00-env.sh
echo "→ selected $TARGET_DISK"
