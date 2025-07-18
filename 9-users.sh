#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

cat <<EOF | chroot $MOUNTPOINT /bin/bash
set -euo pipefail
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "root:$ROOT_PASSWORD" | chpasswd
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
EOF

echo "[+] User $USERNAME created with sudo access."