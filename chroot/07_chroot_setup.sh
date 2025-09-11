#!/bin/bash
set -euo pipefail

# === 変数・環境読み込み ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Inside chroot"

# === タイムゾーン設定 ===
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

# === ロケール設定 ===
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# === キーマップ設定 ===
echo "KEYMAP=jp106" > /etc/vconsole.conf

# === ホスト情報設定 ===
echo "127.0.0.1 localhost" > /etc/hosts
echo "$HOSTNAME" > /etc/hostname

# === パッケージ同期・準備 ===
emerge-webrsync
#emerge --sync --quiet

# === カーネルとファームウェア関連パッケージ ===
#emerge --ask @system
emerge --quiet sys-kernel/gentoo-sources sys-kernel/installkernel linux-firmware @system

# === カーネルビルド用 genkernel 導入 ===
echo ">>> Installing genkernel"
emerge --quiet sys-kernel/genkernel

# === カーネルシンボリックリンク設定 ===
KERNEL_SRC=$(ls -d /usr/src/linux-* | sort -V | tail -n1)
ln -snf "$KERNEL_SRC" /usr/src/linux
eselect kernel set 1

# === genkernel によるカーネルビルド ===
echo ">>> Building kernel with genkernel"
genkernel all

echo "[✓] Kernel and firmware successfully built."

# === 続きのスクリプト実行 ===
for script in /chroot/{08..11}_*.sh; do
  if [[ -x "$script" ]]; then
    echo ">>> Running $script"
    bash "$script"
  else
    echo "Skipping $script (not executable or missing)"
  fi
done
