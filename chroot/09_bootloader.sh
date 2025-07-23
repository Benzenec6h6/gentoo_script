#!/usr/bin/env bash
set -euo pipefail
source ./00_env.sh

emerge --quiet sys-boot/grub sys-kernel/gentoo-sources

if [[ "$BOOTLOADER" == "grub" ]]; then
  if [[ -d /sys/firmware/efi ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=gentoo
  else
    grub-install --target=i386-pc "$DISK"
  fi
  grub-mkconfig -o /boot/grub/grub.cfg
else
  bootctl install
  cp ./assets/loader.conf /assets/loader.conf
  
  TEMPLATE="./assets/gentoo.conf.template"
  OUTPUT="/boot/loader/entries/gentoo.conf"
  cp "$TEMPLATE" "$OUTPUT"
  sed "s|@PARTUUID@|$PARTUUID|g" "$TEMPLATE" > "$OUTPUT"

fi

echo "[+] Bootloader $BOOTLOADER installed."