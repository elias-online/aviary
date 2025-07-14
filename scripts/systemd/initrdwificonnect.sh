#!/bin/sh

if [ -e "/run/systemd/tpm2-srk-public-key.pem" ]; then
    echo "TPM present, stopping script"
    exit 0
fi

if [ ! -e "/sys/class/net/wifi0" ]; then
    echo "No wifi device present, stopping script"
    exit 0
fi

wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-wifi0.conf -i wifi0
