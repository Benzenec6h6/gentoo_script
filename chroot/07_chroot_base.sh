#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Inside chroot - Base setup"

# === タイムゾーン・ロケール・キーマップ・ホスト名 (既存のまま) ===
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
#echo "KEYMAP=jp106" > /etc/vconsole.conf
echo 'keymap="jp106"' > /etc/conf.d/keymaps
echo "127.0.0.1 localhost" > /etc/hosts
echo "$HOSTNAME" > /etc/hostname

# === グラフィックドライバー設定 ===
echo "[+] Setting up video cards..."
mkdir -p /etc/portage/package.use
echo "*/* VIDEO_CARDS: -* virgl qxl gallium" > /etc/portage/package.use/00video_cards

# === パッケージ同期 ===
emerge-webrsync

# === CPU最適化フラグの自動設定 ===
echo "[*] Setting up CPU_FLAGS_X86..."

# 1. ツールをノンインタラクティブでインストール
emerge --oneshot app-portage/cpuid2cpuflags

# 2. ディレクトリが存在することを確認してフラグを書き出し
mkdir -p /etc/portage/package.use
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

echo "[✓] CPU flags successfully configured: $(cpuid2cpuflags)"

# === 循環依存（gpm ↔ ncurses）の強制突破 ===
echo "[*] Breaking circular dependency between gpm and ncurses..."

# 1. 一時的に ncurses の gpm フラグをオフにする設定を書き込む
mkdir -p /etc/portage/package.use
echo "sys-libs/ncurses -gpm" >> /etc/portage/package.use/break-gpm

# 2. 下のログで要求されている libglvnd の X フラグもついでに解決しておく
echo "media-libs/libglvnd X" >> /etc/portage/package.use/glvnd

# 3. 依存の輪を断ち切るために、まず ncurses だけを単体で先行インストール（oneshot）
emerge --oneshot --quiet sys-libs/ncurses

# 4. 先行インストールが終わったら、一時的な設定ファイルを削除して本来のフラグ（プロファイル標準）に戻す
rm /etc/portage/package.use/break-gpm
echo "[✓] Circular dependency broken successfully."

# === プロファイル切り替え (コメント解除) ===
echo "[+] Selecting desktop profile..."
ln -snf /var/db/repos/gentoo/profiles/default/linux/amd64/23.0/desktop /etc/portage/make.profile

# === 最速バイナリホスト (x86-64-v3) の設定を追加 ===
echo "[+] Configuring x86-64-v3 binrepos..."
mkdir -p /etc/portage/binrepos.conf
cat << 'EOF' > /etc/portage/binrepos.conf/gentoo.conf
[gentoo-x86-64-v3]
priority = 9999
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
verify-signature = true
location = /var/cache/binhost/gentoo-v3

[gentoo-x86-64]
priority = 10
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/
verify-signature = true
location = /var/cache/binhost/gentoo-v1
EOF

# === アップデート ===
# ここで @system を更新。x86-64-v3 のバイナリが効くので一瞬で終わります
emerge --update --deep --newuse --changed-use --usepkg @system --quiet

echo "[*] Launching remaining setup scripts..."
for script in /chroot/{08..12}_*.sh; do
  if [[ -x "$script" ]]; then
    echo ">>> Running $script"
    bash "$script"
  else
    echo "Skipping $script (not executable or missing)"
  fi
done
