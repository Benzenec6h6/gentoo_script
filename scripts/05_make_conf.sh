#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00_env.sh"

echo "[+] Selecting make.conf profile for init=${INIT}"

profile_path="./profile/${INIT}/make.conf"

if [[ ! -f "$profile_path" ]]; then
  echo "[!] make.conf for $INIT not found at $profile_path"
  exit 1
fi

cp "$profile_path" "$MOUNTPOINT/etc/portage/make.conf"

echo "[✓] make.conf copied from profile/$INIT"
