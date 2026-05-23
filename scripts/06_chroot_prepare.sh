#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[+] Preparing for chroot..."

# ディレクトリ作成とファイルのコピー
mkdir -p "$MOUNTPOINT"/{proc,sys,dev,run,boot}
cp --dereference /etc/resolv.conf "$MOUNTPOINT/etc/"
cp -r ./chroot "$MOUNTPOINT/chroot"
cp -r ./assets "$MOUNTPOINT/assets"
cp -r ./00_env.sh "$MOUNTPOINT/00_env.sh"

# 安全にマウントするためのヘルパー関数
safe_mount() {
    local type="$1" src="$2" dst="$3" opts="${4:-}"
    if mountpoint -q "$dst"; then
        echo "[-] $dst is already mounted. Skipping."
    else
        if [[ -n "$opts" ]]; then mount -t "$type" -o "$opts" "$src" "$dst"; else mount -t "$type" "$src" "$dst"; fi
    fi
}

safe_bind() {
    local mode="$1" src="$2" dst="$3" slave="${4:-}"
    if mountpoint -q "$dst"; then
        echo "[-] $dst is already mounted. Skipping."
    else
        mount "$mode" "$src" "$dst"
        if [[ -n "$slave" ]]; then mount "$slave" "$dst"; fi
    fi
}

# --- 仮想ファイルシステムのマウント ---
safe_mount "proc" "proc" "$MOUNTPOINT/proc"
safe_bind "--rbind" "/sys" "$MOUNTPOINT/sys" "--make-rslave"
safe_bind "--rbind" "/dev" "$MOUNTPOINT/dev" "--make-rslave"

# INITに関わらず /run は現代のGentooではマウント必須
safe_bind "--bind" "/run" "$MOUNTPOINT/run" "--make-slave"

# --- /dev/shm のシンボリックリンク地雷対策 ---
echo "[+] Checking /dev/shm configuration..."
if [[ -L "$MOUNTPOINT/dev/shm" ]]; then
    echo "[!] $MOUNTPOINT/dev/shm is a symlink. Correcting..."
    rm -f "$MOUNTPOINT/dev/shm"
fi
mkdir -p "$MOUNTPOINT/dev/shm"
# tmpfsとして適切に独立マウントし、権限を1777にする
safe_mount "tmpfs" "shm" "$MOUNTPOINT/dev/shm" "nosuid,nodev,noexec"
chmod 1777 "$MOUNTPOINT/dev/shm"

# --- その他のマウント ---
if ! mountpoint -q "$MOUNTPOINT/boot"; then
    echo "[+] Mounting boot partition..."
    mount "${DISK_BOOT}" "$MOUNTPOINT/boot"
fi

if [[ -d /sys/firmware/efi/efivars ]]; then
    mkdir -p "$MOUNTPOINT/sys/firmware/efi/efivars"
    safe_bind "--bind" "/sys/firmware/efi/efivars" "$MOUNTPOINT/sys/firmware/efi/efivars"
fi

echo "[✓] Ready to chroot."

chroot "$MOUNTPOINT" /bin/bash -l -c "/chroot/07_chroot_setup.sh"
