#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Installing bootloader: $BOOTLOADER"

emerge --quiet sys-boot/grub

if [[ "$BOOTLOADER" == "grub" ]]; then

  echo "[*] Using GRUB bootloader"

  # ---- /etc/default/grub を生成 ----
  if [[ "$is_vm" == "true" ]]; then
    echo "[*] VM detected: applying grub.vm.template"
    sed \
      -e "s|@ROOT_PARTUUID@|$ROOT_PARTUUID|g" \
      "$SCRIPT_DIR/assets/bootloader/grub/grub.vm.template" \
      > /etc/default/grub
  else
    echo "[*] Bare metal detected: using default grub template"
    cp "$SCRIPT_DIR/assets/bootloader/grub/grub.template" /etc/default/grub
  fi

  # ---- UEFI / BIOS 判定 ----
  if [[ -d /sys/firmware/efi ]]; then
    echo "[*] Installing GRUB for UEFI"
    grub-install \
      --target=x86_64-efi \
      --efi-directory=/boot/efi \
      --bootloader-id=gentoo
  else
    echo "[*] Installing GRUB for BIOS"
    grub-install --target=i386-pc "$DISK"
  fi

  # ---- grub.cfg 生成 ----
  grub-mkconfig -o /boot/grub/grub.cfg

else
  echo "[*] Using systemd-boot"

  bootctl install

  cp "$SCRIPT_DIR/assets/bootloader/systemd-boot/loader.conf" \
     /boot/loader/loader.conf

  TEMPLATE="$SCRIPT_DIR/assets/bootloader/systemd-boot/gentoo.conf.template"
  OUTPUT="/boot/loader/entries/gentoo.conf"

  sed "s|@PARTUUID@|$PARTUUID|g" "$TEMPLATE" > "$OUTPUT"
fi

echo "[✓] Bootloader installation completed."
