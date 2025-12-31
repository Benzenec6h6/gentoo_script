#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/00_env.sh"
source "$ENV_FILE"

update_env() {
  local var="$1"
  local val="$2"
  sed -i "/^export ${var}=/d" "$ENV_FILE"
  [[ -s "$ENV_FILE" && "$(tail -c 1 "$ENV_FILE")" != $'\n' ]] && printf '\n' >> "$ENV_FILE"
  printf 'export %s="%s"\n' "$var" "$val" >> "$ENV_FILE"
}

choose_option() {
  local prompt="$1"; shift
  local options=("$@")
  local opt idx
  echo "$prompt" >&2
  select opt in "${options[@]}"; do
    if [[ -n "$opt" ]]; then
      echo "$opt"
      return 0
    else
      echo "Invalid selection, try again." >&2
    fi
  done
}

get_partition_name() {
  local disk="$1"
  local part_num="$2"
  if [[ "$disk" =~ nvme ]]; then
    echo "${disk}p${part_num}"
  else
    echo "${disk}${part_num}"
  fi
}

mapfile -t disks < <(lsblk -ndo NAME,SIZE,TYPE | awk '$3=="disk" && $1!~/^loop/ {print $1, $2}')
(( ${#disks[@]} )) || { echo "No block device found"; exit 1; }

echo "== Select target disk =="
for i in "${!disks[@]}"; do
  printf "%2d) /dev/%s (%s)\n" $((i+1)) "$(awk '{print $1}' <<<"${disks[$i]}")" "$(awk '{print $2}' <<<"${disks[$i]}")"
done

read -rp 'Index: ' idx
((idx >= 1 && idx <= ${#disks[@]})) || { echo "Invalid index"; exit 1; }
TARGET_DISK="/dev/$(awk '{print $1}' <<<"${disks[idx-1]}")"
update_env "TARGET_DISK" "$TARGET_DISK"
echo "→ selected $TARGET_DISK"

# パーティション設定
DISK_BOOT=$(get_partition_name "$TARGET_DISK" 1)
DISK_SWAP=$(get_partition_name "$TARGET_DISK" 2)
DISK_ROOT=$(get_partition_name "$TARGET_DISK" 3)
update_env "DISK_BOOT" "$DISK_BOOT"
update_env "DISK_SWAP" "$DISK_SWAP"
update_env "DISK_ROOT" "$DISK_ROOT"
echo "→ Partitions: boot=$DISK_BOOT swap=$DISK_SWAP root=$DISK_ROOT"

# ネットワーク選択
NETMGR=$(choose_option "== Network tool ==" dhcpcd NetworkManager)
update_env "NETMGR" "$NETMGR"
echo "→ $NETMGR"

# init system 選択
INIT=$(choose_option "== init system ==" openrc systemd)
update_env "INIT" "$INIT"
echo "→ $INIT"

# bootloader 選択
BOOTLOADER=$(choose_option "== Boot loader ==" systemd-boot grub)
update_env "BOOTLOADER" "$BOOTLOADER"
echo "→ $BOOTLOADER"

# username
read -rp "== User name (new account): " username
[[ -n "$username" ]] || { echo "Username must not be empty"; exit 1; }
update_env "USERNAME" "$username"
echo "→ user = $username"

# ---- password ----
read -srp "== Password (new password): " password
echo
read -srp "== Password (confirm): " password2
echo
[[ "$password" == "$password2" ]] || { echo "Passwords do not match"; exit 1; }
update_env "PASSWORD" "$password"

# VM 判定はopenrcだと自動で判定することができなそうなのでユーザーに明示的に選ばせる
PROFILE=$(choose_option "== PROFILE ==" vm laptop)
if [[ "$PROFILE" == "vm" ]]; then
  update_env "is_vm" "true"
else
  update_env "is_vm" "false"
fi
update_env "PROFILE" "$PROFILE"
echo "→ $PROFILE"