#!/bin/sh

systemd_path=$1
mapper_device=$2
disk_path=$3
flags=$4
salt_password=$5
salt_recovery=$6

sleep 300

while [ ! -e "/dev/mapper/$mapper_device" ]; do

    if plymouth --ping || (exit 1); then
        password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system")
    else
        password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system:")
    fi

    hash_password=$(mkpasswd --method=yescrypt --salt="$salt_password" "$password")
    hash_recovery=$(mkpasswd --method=yescrypt --salt="$salt_recovery" "$password")

    umask 0377

    rm -f /luks-key
    printf "%s" "$hash_password" > /luks-key

    rm -f /luks-key-recovery
    printf "%s" "$hash_recovery" > /luks-key-recovery

    umask 0022

    #systemd-cryptsetup attach "$mapper_device" "/dev/disk/by-partlabel/$disk_device" /luks-key discard,headless || echo "/luks-key is incorrect, could not attach $mapper_device"
    $systemd_path/bin/systemd-cryptsetup attach "$mapper_device" "$disk_path" "-" "$flags"

done
