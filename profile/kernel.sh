#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

emerge --quiet sys-kernel/gentoo-sources sys-kernel/genkernel

# genkernel を使ってカーネルビルド（オプション: all または menuconfig）
genkernel --install all

echo "[+] Kernel built using genkernel."