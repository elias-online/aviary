#!/bin/sh

hash_path_new=$1
drive_partlabel_primary=$2
drive_partlabel_secondary=$3

key_new=$(head -n1 "$hash_path_new")

umask 0377

if [ hash_path_new =~ luks-hash$ ]; then
    if [ ! -e "/persist/hash-recovery" ]; then
        printf "%s" "$key_new" > /persist/hash-recovery
        exit 0
    fi
    
    key_old="/persist/hash-recovery"

else
    if [ ! -e "/persist/hash-password" ]; then
        printf "%s" "$key_new" > /persist/hash-password
        exit 0
    fi

    key_old="/persist/hash-password"

fi

drive_primary=$(/run/current-system/sw/bin/cryptsetup status "$drive_partlabel_primary" \
    | grep device: | sed -n 's/^  device:  //p')
drive_secondary=$(/run/current-system/sw/bin/cryptsetup status "$drive_partlabel_secondary" \
    | grep device: | sed -n 's/^  device:  //p')

rm -f /tmp/luks-key-new
printf "%s" "$key_new" > /tmp/luks-key-new

/run/current-system/sw/bin/cryptsetup luksAddKey "$drive_primary" --key-file "$key_old" < /tmp/luks-key-new
/run/current-system/sw/bin/cryptsetup luksRemoveKey "$drive_primary" --key-file "$key_old"

if [ -n "$drive_secondary" ]; then
    /run/current-system/sw/bin/cryptsetup luksAddKey "$drive_secondary" --key-file "$key_old" < /tmp/luks-key-new
    /run/current-system/sw/bin/cryptsetup luksRemoveKey "$drive_secondary" --key-file "$key_old"
fi

rm -f /tmp/luks-key-new

rm -f "$key_old"
printf "%s" "$key_new" > "$key_old"
