#!/usr/bin/env bash
set -euo pipefail

# === スクリプトのあるディレクトリに移動して環境変数を読み込む ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../00_env.sh"

echo "[*] Downloading Stage3 for $ARCH with $INIT..."

cd "$MOUNTPOINT"

BASE_URL="https://bouncer.gentoo.org/fetch/root/all/releases/$ARCH/autobuilds"
INFO_URL="${BASE_URL}/latest-stage3-${ARCH}-${INIT}.txt"

# === 最新の tarball 情報を取得 ===
TARBALL_PATH=$(curl -fsSL "$INFO_URL" | grep -v '^#' | awk '{print $1}')
TARBALL_DIR=$(dirname "$TARBALL_PATH")
FILENAME=$(basename "$TARBALL_PATH")

TARBALL_URL="${BASE_URL}/${TARBALL_PATH}"
DIGEST_URL="${TARBALL_URL}.DIGESTS"

# === ダウンロード ===
echo "[*] Downloading $FILENAME..."
wget -q --show-progress "$TARBALL_URL"
wget -q "$DIGEST_URL"

# === チェックサム検証 ===
echo "[*] Verifying checksum..."
grep "$FILENAME" "$(basename "$DIGEST_URL")" | grep SHA512 | sha512sum -c -

if [[ $? -ne 0 ]]; then
  echo "[!] SHA512 verification failed. Exiting."
  exit 1
fi

# === 展開 ===
echo "[*] Extracting $FILENAME to $MOUNTPOINT..."
tar xpvf "$FILENAME" --xattrs-include='*.*' --numeric-owner

# === 後始末 ===
rm "$FILENAME" "$(basename "$DIGEST_URL")"

echo "[✓] Stage3 downloaded and extracted."
