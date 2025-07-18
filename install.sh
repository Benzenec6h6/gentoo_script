#!/usr/bin/env bash
set -euo pipefail

# === 実行前チェック ===
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 環境変数ロード ===
source "$SCRIPT_DIR/00-env.sh"

# === ステップ実行 ===
for step in \
  01-disk-select.sh \
  02-network-select.sh \
  03-bootloader-select.sh \
  04-stage3.sh \
  05-make-conf.sh \
  06-mount.sh \
  07-chroot-prepare.sh \
  08-chroot-exec.sh \
  09-users.sh \
  10-bootloader.sh \
  11-cleanup.sh \
  12-postinstall.sh

do
  echo "[→] Running $step..."
  bash "$SCRIPT_DIR/$step"
done

echo "[✓] Gentoo installation complete. Reboot your system."