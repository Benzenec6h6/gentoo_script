#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

# 必要パッケージ
emerge --verbose \
  media-fonts/noto-cjk \
  app-portage/gentoolkit \
  net-misc/networkmanager \
  app-misc/fastfetch \
  dev-vcs/git

rc-update add NetworkManager default
