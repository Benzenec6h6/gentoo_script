#!/usr/bin/env bash
set -euo pipefail

# 共通変数
export MOUNTPOINT="/mnt/gentoo"
export ARCH="amd64"
export HOSTNAME="gentoo"
export TIMEZONE="Asia/Tokyo"
export TARGET_DISK=""
export INIT=""
export BOOTLOADER=""
export NETMGR=""
export USERNAME=""
export PARTUUID=""
export is_vm=""
