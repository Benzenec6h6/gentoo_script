#!/usr/bin/env bash
set -euo pipefail
source ./00-env.sh

useradd -m -G wheel -s /bin/bash "$USERNAME"
echo root:root | chpasswd
echo "$USERNAME:$USERNAME" | chpasswd

# sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[+] User $USERNAME created with sudo access."