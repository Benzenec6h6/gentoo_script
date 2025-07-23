#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00_env.sh"

useradd -m -G wheel -s /bin/bash "$USERNAME"
echo root:root | chpasswd
echo "$USERNAME:$USERNAME" | chpasswd

# sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[+] User $USERNAME created with sudo access."