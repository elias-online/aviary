#!/bin/sh

mapper_device=$1

if [ ! -e "/dev/mapper/$mapper_device" ]; then
    exit 0
fi

systemd-cryptsetup detach "$mapper_device";
