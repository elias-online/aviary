#!/bin/sh

mapper_device=$1
disk_device=$2

if [ -e "/dev/mapper/$mapper_device" ]; then
    exit 0
fi

systemd-cryptsetup attach "$mapper_device" "/dev/disk/by-partlabel/$disk_device" /luks-key discard,headless;
