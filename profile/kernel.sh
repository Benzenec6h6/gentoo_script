#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

cat <<EOF | chroot $MOUNTPOINT /bin/bash
set -euo pipefail

emerge --quiet sys-kernel/gentoo-sources sys-kernel/genkernel

# genkernel を使ってカーネルビルド（オプション: all または menuconfig）
genkernel --install all

EOF

echo "[+] Kernel built using genkernel."