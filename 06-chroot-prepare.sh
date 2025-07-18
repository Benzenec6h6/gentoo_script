#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

echo "[+] Preparing for chroot..."

cp --dereference /etc/resolv.conf "$MOUNTPOINT/etc/"

mount --types proc /proc "$MOUNTPOINT/proc"
mount --rbind /sys "$MOUNTPOINT/sys"
mount --make-rslave "$MOUNTPOINT/sys"
mount --rbind /dev "$MOUNTPOINT/dev"
mount --make-rslave "$MOUNTPOINT/dev"

echo "[✓] Ready to chroot."
