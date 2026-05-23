#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Compiling and installing kernel..."

# 必要パッケージの導入
emerge --quiet sys-kernel/gentoo-sources linux-firmware

# ソース特定
KERNEL_SRC=$(ls -d /usr/src/linux-* | sort -V | tail -n1)
ln -snf "$KERNEL_SRC" /usr/src/linux
cd "$KERNEL_SRC"

# コンフィグ適用 (既存のまま)
if [[ "$is_vm" == "true" ]]; then
  make ARCH="$KERNEL_ARCH" defconfig
  ./scripts/kconfig/merge_config.sh -m .config \
    kernel/configs/kvm_guest.config \
    /assets/kernel/vm/qemu.config
else
  cp /profile/kernel/laptop/kernel.config .config
  cat /profile/kernel/laptop/baremetal.config >> .config 
fi
make ARCH="$KERNEL_ARCH" olddefconfig

# ビルド実行
make ARCH="$KERNEL_ARCH" -j$(nproc)
make ARCH="$KERNEL_ARCH" modules_install

# 🔥 運命の1行
# これを実行した瞬間、Portage(installkernel)が裏で自動的に：
# 1. dracut を安全なオプションで回して initramfs を自動生成
# 2. カーネルとinitramfsを /boot (ESP) の正しい階層へコピー
# 3. systemd-boot 用の個別エントリー(.conf) を自動生成
# をノンストップで全自動処理してくれます！
make ARCH="$KERNEL_ARCH" install

echo "[✓] Kernel installed and hooks triggered successfully."
