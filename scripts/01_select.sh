#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/00_env.sh"

update_env() {
  local var="$1"
  local val="$2"
  sed -i "/^export ${var}=/d" "$ENV_FILE"
  if [[ -s "$ENV_FILE" && "$(tail -c 1 "$ENV_FILE")" != $'\n' ]]; then
    printf '\n' >> "$ENV_FILE"
  fi
  printf 'export %s="%s"\n' "$var" "$val" >> "$ENV_FILE"
}

# select / read を共通化
choose_option() {
  local prompt="$1"; shift
  local options=("$@")
  local opt
  printf '%s\n' "$prompt" >&2
  exec 3>&1
  {
    PS3="> "
    select opt in "${options[@]}"; do
      if [[ -n $opt ]]; then
        printf '%s\n' "$opt" >&3
        break
      fi
    done
  } 1>&2
  exec 3>&-
}

# パーティション名取得
get_partition_name() {
    local disk="$1"
    local part_num="$2"
    if [[ "$disk" =~ nvme ]]; then
        echo "${disk}p${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

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

# ---- パーティション設定 ----
DISK_BOOT=$(get_partition_name "$TARGET_DISK" 1)
DISK_SWAP=$(get_partition_name "$TARGET_DISK" 2)
DISK_ROOT=$(get_partition_name "$TARGET_DISK" 3)
update_env "DISK_BOOT" "$DISK_BOOT"
update_env "DISK_SWAP" "$DISK_SWAP"
update_env "DISK_ROOT" "$DISK_ROOT"
echo "→ Partitions: boot=$DISK_BOOT swap=$DISK_SWAP root=$DISK_ROOT"

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
