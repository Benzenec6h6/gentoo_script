#!/bin/bash
set -euo pipefail

source /etc/profile
export PS1="(chroot) # "

echo "[*] Setting locale and timezone..."
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo "Asia/Tokyo" > /etc/timezone

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "[*] Setting hostname and hosts"
echo "gentoo" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   gentoo.localdomain gentoo
EOF

echo "[*] Syncing Portage tree..."
emerge --sync --quiet

echo "[*] Installing kernel and firmware..."
emerge --ask --quiet sys-kernel/gentoo-sources sys-kernel/installkernel linux-firmware

echo "[✓] Basic chroot setup complete"
