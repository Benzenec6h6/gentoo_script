#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[*] Downloading Stage3 for $ARCH with $INIT..."

cd "$MOUNTPOINT"

BASE_URL="https://bouncer.gentoo.org/fetch/root/all/releases/$ARCH/autobuilds"
INFO_URL="${BASE_URL}/latest-stage3-${ARCH}-${INIT}.txt"

TARBALL_PATH=$(curl -s "$INFO_URL" | grep -v '^#' | awk '{print $1}')
TARBALL_URL="${BASE_URL}/${TARBALL_PATH}"
DIGEST_URL="${TARBALL_URL}.DIGESTS"
FILENAME=$(basename "$TARBALL_PATH")

wget -q --show-progress "$TARBALL_URL"
wget -q "$DIGEST_URL"

echo "[*] Verifying checksum..."
grep "$FILENAME" "$FILENAME.DIGESTS" | grep SHA512 | sha512sum -c -

if [[ $? -ne 0 ]]; then
  echo "[!] SHA512 verification failed. Exiting."
  exit 1
fi

echo "[*] Extracting $FILENAME to $MOUNTPOINT..."
tar xpvf "$FILENAME" --xattrs-include='*.*' --numeric-owner

rm "$FILENAME" "$FILENAME.DIGESTS"
echo "[✓] Stage3 downloaded and extracted."
