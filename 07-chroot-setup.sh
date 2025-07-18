#!/bin/bash
set -euo pipefail

echo "[*] Inside chroot"

ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=jp106"     > /etc/vconsole.conf
echo "127.0.0.1 localhost" > /etc/hosts
echo "gentoo" > /etc/hostname

emerge --sync
emerge --ask sys-kernel/gentoo-sources sys-kernel/installkernel linux-firmware

echo "[✓] Kernel sources & firmware installed"
