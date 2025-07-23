#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

if [[ -f /sys/class/dmi/id/product_name ]] && grep -qi virtual /sys/class/dmi/id/product_name; then
  echo "[INFO] Running in virtual machine"
  sed -i "s|^export is_vm=.*|export is_vm="true"|" ./00_env.sh
else
  echo "[INFO] Running on physical hardware"
  sed -i "s|^export is_vm=.*|export is_vm="false"|" ./00_env.sh
fi

mapfile -t disks < <(lsblk -ndo NAME,SIZE,TYPE | awk '$3=="disk" && $1!~/^loop/ {print $1, $2}')

if ((${#disks[@]}==0)); then
  echo "No block device found"; exit 1
fi

echo "== Select target disk =="
for i in "${!disks[@]}"; do
  printf "%2d) /dev/%s (%s)\n" $((i+1)) \
    "$(awk '{print $1}' <<<"${disks[$i]}")" \
    "$(awk '{print $2}' <<<"${disks[$i]}")"
done

read -rp 'Index: ' idx
((idx >= 1 && idx <= ${#disks[@]})) || { echo "Invalid index"; exit 1; }
TARGET_DISK="/dev/$(awk '{print $1}' <<<"${disks[idx-1]}")"
sed -i "s|^export TARGET_DISK=.*|export TARGET_DISK=\"$TARGET_DISK\"|" ./00_env.sh
echo "→ selected $TARGET_DISK"

nets=(dhcpcd NetworkManager)
echo "== Network tool =="
select net in "${nets[@]}"; do [[ -n $net ]] && break; done
sed -i "s|^export NETMGR=.*|export NETMGR=\"$net\"|" ./00_env.sh
echo "→ $net"

inits=(openrc systemd)
echo "== init system =="
select init in "${inits[@]}"; do [[ -n $inits ]] && break; done
sed -i "s|^export INIT=.*|export INIT=\"$init\"|" ./00_env.sh
echo "→ $init"

loaders=(systemd-boot grub)
echo "== Boot loader =="
select loader in "${loaders[@]}"; do [[ -n $loader ]] && break; done
sed -i "s|^export BOOTLOADER=.*|export BOOTLOADER=\"$loader\"|" ./00_env.sh
echo "→ $loader"

#add username
read -rp "== User name (new account): " username
[[ -n $username ]] || { echo "Username must not be empty"; exit 1; }
sed -i "s|^export USERNAME=.*|export USERNAME=\"$username\"|" ./00_env.sh
echo "→ user = $username"
