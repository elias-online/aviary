#!/bin/sh

hash_path_old=$1
hash_path_new=$2
drive_partlabel_primary=$3
drive_partlabel_secondary=$4

key_old=$(head -n1 "$hash_path_old")
key_new=$(head -n1 "$hash_path_new")
drive_primary=$(/run/current-system/sw/bin/cryptsetup status "$drive_partlabel_primary" \
    | grep device: | sed -n 's/^  device:  //p')
drive_secondary=$(/run/current-system/sw/bin/cryptsetup status "$drive_partlabel_secondary" \
    | grep device: | sed -n 's/^  device:  //p')

printf "%s" "$key_old" > /tmp/luks-key-old
chmod 0400 /tmp/luks-key-old
printf "%s" "$key_new" > /tmp/luks-key-new
chmod 0400 /tmp/luks-key-new

/run/current-system/sw/bin/cryptsetup luksAddKey "$drive_primary" --key-file /tmp/luks-key-old < /tmp/luks-key-new
/run/current-system/sw/bin/cryptsetup luksRemoveKey "$drive_primary" --key-file /tmp/luks-key-old

if [ -n "$drive_secondary" ]; then
    /run/current-system/sw/cryptsetup luksAddKey "$drive_secondary" --key-file /tmp/luks-key-old < /tmp/luks-key-new
    /run/current-system/sw/cryptsetup luksRemoveKey "$drive_secondary" --key-file /tmp/luks-key-old
fi

rm -f /tmp/luks-key-old
rm -f /tmp/luks-key-new
