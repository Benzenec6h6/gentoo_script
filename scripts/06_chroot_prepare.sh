#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[+] Preparing for chroot..."

cp --dereference /etc/resolv.conf "$MOUNTPOINT/etc/"
cp -r ./chroot "$MOUNTPOINT/chroot"
cp -r ./assets "$MOUNTPOINT/assets"
cp -r ./profile "$MOUNTPOINT/profile"
cp -r ./00_env.sh "$MOUNTPOINT/00_env.sh"

#mount "${DISK_ROOT}" "$MOUNTPOINT"             # 二重マウントになっている可能性ありコメントアウトで様子見
#mount --mkdir "${DISK_BOOT}" "$MOUNTPOINT/boot" # /boot が別パーティションの場合
#if [[ -d /sys/firmware/efi ]]; then
#    mount --mkdir "${DISK_BOOT}" "$MOUNTPOINT/efi"  # ここも二重マウントのときと同様03の内容とかぶっている
#fi

mount --types proc /proc "$MOUNTPOINT/proc"
mount --rbind /sys "$MOUNTPOINT/sys"
mount --make-rslave "$MOUNTPOINT/sys"
mount --rbind /dev "$MOUNTPOINT/dev"
mount --make-rslave "$MOUNTPOINT/dev"

if [[ $INIT == "systemd" ]]; then
    mount --bind /run "$MOUNTPOINT/run"   # systemd 使用時に推奨
fi
echo "[✓] Ready to chroot."

chroot "$MOUNTPOINT" /chroot/07_chroot_setup.sh
