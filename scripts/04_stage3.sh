#!/usr/bin/env bash
set -uxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../00_env.sh"

# 日本国内の信頼できるミラーリスト
MIRRORS=(
    "https://ftp.jaist.ac.jp/pub/Linux/Gentoo"
    "https://mirror.linux.jp/gentoo"
    "https://ftp.riken.jp/Linux/gentoo"
)

echo "[*] Downloading Stage3 for $GENTOO_ARCH with $INIT..."
cd "$MOUNTPOINT"

SUCCESS=false

for MIRROR in "${MIRRORS[@]}"; do
    echo "[-] Trying Mirror: $MIRROR"
    
    # 1. メタデータURLの構築
    # ミラーの場合は releases/$ARCH/autobuilds/ 直下に最新情報がある
    BASE_AUTOBULDS="${MIRROR}/releases/${GENTOO_ARCH}/autobuilds"
    INFO_URL="${BASE_AUTOBULDS}/latest-stage3-${GENTOO_ARCH}-${INIT}.txt"
    
    # 2. TARBALLパスを取得（リトライ付き）
    TARBALL_PATH=$(curl -fsSL --retry 2 --connect-timeout 5 "$INFO_URL" | grep -v '^#' | grep ".tar.xz" | head -n1 | awk '{print $1}') || continue
    
    # URLを組み立てる
    FILENAME=$(basename "$TARBALL_PATH")
    TARBALL_URL="${BASE_AUTOBULDS}/${TARBALL_PATH}"
    DIGEST_URL="${TARBALL_URL}.DIGESTS"
    
    echo "[*] Target URL: $TARBALL_URL"

    # 3. 本体ダウンロード（404なら即座に次のミラーへ）
    if wget -c --tries=3 --timeout=20 --show-progress "$TARBALL_URL"; then
        wget -q "$DIGEST_URL" -O "${FILENAME}.DIGESTS"
        DIGEST_FILE="${FILENAME}.DIGESTS"

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

        SUCCESS=true
        break
    else
        echo "[!] Download failed (possibly 404 or Timeout). Trying next..."
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "[!!!] All attempts failed. Please check the network or GENTOO_ARCH/INIT settings."
    exit 1
fi

# === 展開 ===
echo "[*] Extracting $FILENAME..."
tar xpvf "$FILENAME" --xattrs-include='*.*' --numeric-owner

# === 後処理 ===
rm -f "$FILENAME" "${FILENAME}.DIGESTS"
echo "[✓] Stage3 successfully installed."