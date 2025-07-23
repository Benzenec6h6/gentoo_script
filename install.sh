#!/usr/bin/env bash
set -euo pipefail

# === 実行前チェック ===
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 環境変数ロード ===
source "$SCRIPT_DIR/00_env.sh"

# === ステップ実行 ===
for script in ./scripts/{01..06}_*.sh; do
  echo "==> Running $script"
  bash "$script"
done

echo "[✓] Gentoo installation complete. Reboot your system."