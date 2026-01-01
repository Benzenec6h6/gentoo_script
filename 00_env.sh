#!/usr/bin/env bash
set -euo pipefail

# 共通変数
export MOUNTPOINT="/mnt/gentoo"
# Gentoo用（stage3 / profile）
export GENTOO_ARCH="amd64"
# カーネル用
export KERNEL_ARCH="x86"
export HOSTNAME="gentoo"
export TIMEZONE="Asia/Tokyo"
export TARGET_DISK=""
export DISK_BOOT=""   
export DISK_SWAP=""   
export DISK_ROOT=""   
export INIT=""
export BOOTLOADER=""
export NETMGR=""
export USERNAME=""
export PASSWORD=""
export ROOT_PARTUUID=""
export SWAP_PARTUUID=""
export EFI_PARTUUID=""
export PROFILE=""
export is_vm=""
