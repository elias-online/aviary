#!/bin/sh

hash_check_password=$1
hash_check_recovery=$2

regex='^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$'
if [[ $hash_check_password =~ $regex ]]; then
  salt_check_password=${BASH_REMATCH[0]}
else
  echo "No salt matched for hash_check_password, exiting..."
  exit 1
fi
if [[ $hash_check_recovery =~ $regex ]]; then
  salt_check_recovery=${BASH_REMATCH[0]}
else
  echo "No salt matched for hash_check_recovery, exiting..."
  exit 1
fi

hash_password=""
hash_recovery=""
while [[ "$hash_password" != "$hash_check_password" && "$hash_recovery" != "$hash_check_recovery" ]]; do
    sleep 3
    if plymouth --ping || false; then
        password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system")
    else
        password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system:")
    fi

    hash_password=$(mkpasswd --method=yescrypt --salt="$salt_check_password" "$password")
    hash_recovery=$(mkpasswd --method=yescrypt --salt="$salt_check_recovery" "$password")
done

rm -f /luks-key
printf "%s" "$hash_password" > /luks-key
chmod 0400 /luks-key

rm -f /luks-key-recovery
printf "%s" "$hash_recovery" > /luks-key-recovery
chmod 0400 /luks-key-recovery

echo "Hash completed successfully!";
