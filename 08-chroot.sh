#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

echo "[+] Copying chroot setup script"

mkdir -p "$MOUNTPOINT/chroot"
cp ./chroot/chroot-setup.sh "$MOUNTPOINT/chroot/chroot-setup.sh"
chmod +x "$MOUNTPOINT/chroot/chroot-setup.sh"

echo "[+] Preparing bind mounts..."
cp --dereference /etc/resolv.conf "$MOUNTPOINT/etc/"

mount --types proc /proc "$MOUNTPOINT/proc"
mount --rbind /sys "$MOUNTPOINT/sys"
mount --make-rslave "$MOUNTPOINT/sys"
mount --rbind /dev "$MOUNTPOINT/dev"
mount --make-rslave "$MOUNTPOINT/dev"

echo "[+] Entering chroot"
chroot "$MOUNTPOINT" /chroot/chroot-setup.sh

echo "[✓] Chroot phase completed"
