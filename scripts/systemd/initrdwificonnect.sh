#!/bin/sh

mapper_device=$1

if [ -e "/dev/mapper/$mapper_device" ]; then
    echo "Mapper device already unlocked with TPM, exiting..."
    exit 0
fi

if [ ! -e "/sys/class/net/wifi0" ]; then
    echo "No wifi device present, stopping script..."
    exit 0
fi

wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-wifi0.conf -i wifi0
