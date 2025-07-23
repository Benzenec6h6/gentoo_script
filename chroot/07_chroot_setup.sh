#!/bin/bash
set -euo pipefail

echo "[*] Inside chroot"

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=jp106"     > /etc/vconsole.conf
echo "127.0.0.1 localhost" > /etc/hosts
echo "$HOSTNAME" > /etc/hostname
#cp /etc/hosts

emerge --sync
emerge --ask sys-kernel/gentoo-sources sys-kernel/installkernel linux-firmware
echo ">>> Installing genkernel and gentoo-sources"
emerge --quiet sys-kernel/gentoo-sources sys-kernel/genkernel

echo ">>> Building kernel with genkernel"
genkernel all

echo "[✓] Kernel sources & firmware installed"

for script in /chroot/{08..11}_*.sh; do
  bash "$script"
done
