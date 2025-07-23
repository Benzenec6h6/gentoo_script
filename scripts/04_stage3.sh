#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Downloading Stage3 for $ARCH with $INIT..."

cd "$MOUNTPOINT"

BASE_URL="https://bouncer.gentoo.org/fetch/root/all/releases/$ARCH/autobuilds"
INFO_URL="${BASE_URL}/latest-stage3-${ARCH}-${INIT}.txt"

echo "[*] Fetching latest stage3 info from: $INFO_URL"
TARBALL_PATH=$(curl -fsSL "$INFO_URL" | grep -v '^#' | awk '{print $1}') || {
  echo "[!] Failed to fetch stage3 info"; exit 1;
}

TARBALL_DIR=$(dirname "$TARBALL_PATH")
FILENAME=$(basename "$TARBALL_PATH")
TARBALL_URL="${BASE_URL}/${TARBALL_PATH}"
DIGEST_URL="${TARBALL_URL}.DIGESTS"

echo "[*] Downloading: $TARBALL_URL"
wget -q --show-progress "$TARBALL_URL"
wget -q "$DIGEST_URL"

echo "[*] Verifying checksum for $FILENAME..."
sha512_line=$(grep -A1 "SHA512 HASH" "$FILENAME.DIGESTS" | tail -n1)
echo "$sha512_line" | sha512sum -c - || {
  echo "[!] SHA512 verification failed"; exit 1;
}

echo "[*] Extracting..."
tar xpvf "$FILENAME" --xattrs-include='*.*' --numeric-owner

rm "$FILENAME" "$FILENAME.DIGESTS"
echo "[✓] Stage3 downloaded and extracted."