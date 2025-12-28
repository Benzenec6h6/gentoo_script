#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

# 必要パッケージ
emerge --verbose \
  x11-base/xorg-drivers \
  x11-base/xorg-server \
  x11-wm/openbox \
  x11-terms/xterm \
  x11-misc/tint2 \
  x11-misc/picom \
  lxappearance \
  net-misc/networkmanager \
  network-manager-applet \
  app-misc/fastfetch \
  git


rc-update add NetworkManager default

# ユーザー用ホームディレクトリに dotfiles クローン
#sudo -u $USERNAME bash <<'INNER'
#cd ~
#git clone --depth 1 https://github.com/Benzenec6h6/dotfiles.git
#cp -r dotfiles/gentoo_dot/. ~/
#rm -rf dotfiles
#INNER

# xinitrc
echo "exec openbox-session" > /home/$USERNAME/.xinitrc

# 権限の修正
chown -R $USERNAME:$USERNAME /home/$USERNAME
