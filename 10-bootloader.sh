#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

cat <<EOF | chroot $MOUNTPOINT /bin/bash
set -euo pipefail
emerge --quiet sys-boot/grub sys-kernel/gentoo-sources

if [[ "$LOADER" == "grub" ]]; then
  if [[ -d /sys/firmware/efi ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=gentoo
  else
    grub-install --target=i386-pc "$DISK"
  fi
  grub-mkconfig -o /boot/grub/grub.cfg
else
  bootctl install
  cat > /boot/loader/loader.conf <<LOADER
  default gentoo
  timeout 3
  editor 0
LOADER

  cat > /boot/loader/entries/gentoo.conf <<ENTRY
title   Gentoo Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$ROOT_UUID rw
ENTRY
fi
EOF

echo "[+] Bootloader $LOADER installed."