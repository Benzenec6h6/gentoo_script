#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Installing bootloader: $BOOTLOADER"

if [[ "$BOOTLOADER" == "grub" ]]; then

  echo "[*] Using GRUB bootloader"
  emerge --quiet sys-boot/grub

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
  mkdir -p /etc/portage/package.use
  echo "sys-apps/systemd-utils boot kernel-install" >> /etc/portage/package.use/systemd-utils
  emerge --oneshot --verbose sys-apps/systemd-utils 
  bootctl install

  mkdir -p /boot/loader/entries

  cp "$SCRIPT_DIR/assets/bootloader/systemd-boot/loader.conf" \
    /boot/loader/loader.conf

  KERNEL_VERSION=$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')
  echo "[+] Detected kernel version: $KERNEL_VERSION"

  OUTPUT="/boot/loader/entries/gentoo.conf"

  sed \
    -e "s|@PARTUUID@|$ROOT_PARTUUID|g" \
    -e "s|vmlinuz-linux|vmlinuz-${KERNEL_VERSION}|g" \
    -e "s|initramfs-linux.img|initramfs-${KERNEL_VERSION}.img|g" \
    "$TEMPLATE" > "$OUTPUT"

  echo "[+] Generated bootloader entry:"
  cat "$OUTPUT"
fi

echo "[✓] Bootloader installation completed."
