#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Preparing bootloader structure: $BOOTLOADER"

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

  # === systemd-boot の全自動受け入れ設定 ===
  mkdir -p /etc/portage/package.use
  cat << 'EOF' >> /etc/portage/package.use/bootloader
sys-apps/systemd-utils boot kernel-install
sys-kernel/installkernel systemd systemd-boot dracut
EOF

  # 先に installkernel と dracut を入れておく
  emerge --quiet --usepkg sys-kernel/installkernel sys-kernel/dracut

  # カーネルパラメータの指定
  mkdir -p /etc/kernel
  echo "root=PARTUUID=${ROOT_PARTUUID} rw quiet splash" > /etc/kernel/cmdline
  mkdir -p /etc/cmdline.d
  ln -snf /etc/kernel/cmdline /etc/cmdline.d/00-installkernel.conf

  # fstab を先に作る（dracut がビルド時にマウント情報を参照するため、ここにあると完璧です）
  echo "[*] Generating /etc/fstab"
  TEMPLATE="$SCRIPT_DIR/assets/profile/fstab.template"
  sed \
    -e "s|@ROOT_PARTUUID@|$ROOT_PARTUUID|g" \
    -e "s|@SWAP_PARTUUID@|$SWAP_PARTUUID|g" \
    -e "s|@EFI_PARTUUID@|$EFI_PARTUUID|g" \
    "$TEMPLATE" > /etc/fstab

  # systemd-bootの初期化
  bootctl --esp-path=/boot install
fi
