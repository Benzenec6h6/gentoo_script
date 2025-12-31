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
#echo "KEYMAP=jp106" > /etc/vconsole.conf これはsystemd
echo 'keymap="jp106"' > /etc/conf.d/keymaps #こちらはopenrc

# === ホスト情報設定 ===
echo "127.0.0.1 localhost" > /etc/hosts
echo "$HOSTNAME" > /etc/hostname

# === パッケージ同期・準備 ===
emerge-webrsync
#emerge --sync --quiet

# === カーネルとファームウェア関連パッケージ ===
emerge --quiet @system
emerge --quiet sys-kernel/gentoo-sources sys-kernel/installkernel linux-firmware

# === カーネルソース特定 ===
KERNEL_SRC=$(ls -d /usr/src/linux-* | sort -V | tail -n1)
echo ">>> Using kernel source: $KERNEL_SRC"
cd "$KERNEL_SRC"

# === config 適用 ===
if [[ "$is_vm" == "true" ]]; then
  echo ">>> VM detected: applying QEMU kernel config"
  cp /profile/kernel/vm/common.config .config
  cat /profile/kernel/vm/qemu.config >> .config
else
  echo ">>> Bare metal detected"
  cp /profile/kernel/laptop/kernel.config .config
  cat /profile/kernel/laptop/baremetal.config >> .config
fi

make ARCH="$KERNEL_ARCH" olddefconfig
make ARCH="$KERNEL_ARCH" -j$(nproc)
make ARCH="$KERNEL_ARCH" modules_install
make ARCH="$KERNEL_ARCH" install

# === /usr/src/linux symlink 更新（後処理）===
ln -snf "$KERNEL_SRC" /usr/src/linux

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
