#!/usr/bin/env bash
set -uxo pipefail

# スクリプトディレクトリに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../00_env.sh"

echo "[*] Downloading Stage3 for $GENTOO_ARCH with $INIT..."

cd "$MOUNTPOINT"

# === Stage3 メタデータ取得 ===
BASE_URL="https://bouncer.gentoo.org/fetch/root/all/releases/${GENTOO_ARCH}/autobuilds"
INFO_URL="${BASE_URL}/latest-stage3-${GENTOO_ARCH}-${INIT}.txt"

# TARBALL 情報の取得
TARBALL_PATH=$(curl -fsSL "$INFO_URL" \
    | grep -E 'stage3-.*\.tar\.xz' \
    | head -n1 \
    | awk '{print $1}')

#TARBALL_DIR=$(dirname -- "$TARBALL_PATH")
FILENAME=$(basename "$TARBALL_PATH")
TARBALL_URL="${BASE_URL}/${TARBALL_PATH}"
DIGEST_URL="${BASE_URL}/${TARBALL_PATH}.DIGESTS"
DIGEST_FILE="${FILENAME}.DIGESTS"

echo "[*] Downloading:"
echo "    $FILENAME"
echo "    $DIGEST_FILE"

# === ダウンロード ===
wget -q --show-progress "$TARBALL_URL"
wget -q "$DIGEST_URL" -O "$DIGEST_FILE"

# === SHA512 チェックサム検証 ===
echo "[*] Verifying SHA512 checksum..."
SHA_LINE=$(awk -v filename_regex="^stage3-.*\.tar\.xz$" '
    BEGIN {found=0}
    /SHA512 HASH/ {found=1; next}
    found && $2 ~ filename_regex {print $0; exit}
' "$DIGEST_FILE")

if [[ -z "$SHA_LINE" ]]; then
    echo "[!] Could not find SHA512 hash in DIGESTS"
    exit 1
fi

echo "$SHA_LINE" | sha512sum -c -

# === 展開 ===
echo "[*] Extracting $FILENAME to $MOUNTPOINT..."
tar xpvf "$FILENAME" --xattrs-include='*.*' --numeric-owner

# === 後処理 ===
rm -f "$FILENAME" "$DIGEST_FILE"
echo "[✓] Stage3 downloaded and extracted."