#!/bin/sh

mapper_device=$1

if [ -e "/dev/mapper/$mapper_device" ]; then
    exit 0
fi

if plymouth --ping || false; then
    password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system")
else
    password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system:")
fi

hash_password=$(mkpasswd --method=yescrypt --salt="$salt_check_password" "$password")
hash_recovery=$(mkpasswd --method=yescrypt --salt="$salt_check_recovery" "$password")

rm -f /luks-key
printf "%s" "$hash_password" > /luks-key
chmod 0400 /luks-key

rm -f /luks-key-recovery
printf "%s" "$hash_recovery" > /luks-key-recovery
chmod 0400 /luks-key-recovery
