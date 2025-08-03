#!/bin/sh

device_mapper=$1

mount "$device_mapper" /mnt
btrfs quota enable /mnt
btrfs qgroup limit 64G /mnt/nix

totalFilesystemSize=$(btrfs filesystem usage -g /mnt | grep "Device size:" | \
    sed -n 's/Device size:[[:space:]]*\([0-9.]*\)GiB/\1/p')

homeQuotaSize=$(awk "BEGIN {print int($totalFilesystemSize - 72)}")

btrfs qgroup limit ''${homeQuotaSize}G /mnt/home
umount /mnt
