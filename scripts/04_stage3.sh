#!/usr/bin/env bash
set -euo pipefail

# スクリプトディレクトリに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../00_env.sh"

echo "[*] Downloading Stage3 for $ARCH with $INIT..."

cd "$MOUNTPOINT"

# === Stage3 メタデータ取得 ===
BASE_URL="https://bouncer.gentoo.org/fetch/root/all/releases/${ARCH}/autobuilds"
INFO_URL="${BASE_URL}/latest-stage3-${ARCH}-${INIT}.txt"

# TARBALL 情報の取得
TARBALL_PATH=$(curl -fsSL "$INFO_URL" | grep 'stage3-' | head -n1 | awk '{print $1}')
#TARBALL_DIR=$(dirname -- "$TARBALL_PATH")
FILENAME=$(basename -- "$TARBALL_PATH")

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

grep "  $FILENAME\$" "$DIGEST_FILE" | sha512sum -c -

if [[ $? -ne 0 ]]; then
  echo "[!] SHA512 verification failed. Exiting."
  exit 1
fi

# === 展開 ===
echo "[*] Extracting $FILENAME to $MOUNTPOINT..."
tar xpvf "$FILENAME" --xattrs-include='*.*' --numeric-owner

# === 後処理 ===
rm "$FILENAME" "$DIGEST_FILE"
echo "[✓] Stage3 downloaded and extracted."
