HASH_PATH_OLD=$1 #${config.sops.secrets."${config.aviary.secrets.passwordHashPrevious}".path}
HASH_PATH_NEW=$2 #${config.sops.secrets."${config.aviary.secrets.passwordHash}".path}
DRIVE_PARTLABEL_PRIMARY=$3   #${primary}
DRIVE_PARTLABEL_SECONDARY=$4 #${secondary}

KEY_OLD=$(head -n1 "$HASH_PATH_OLD")
KEY_NEW=$(head -n1 "$HASH_PATH_NEW")
DRIVE_PRIMARY=$(/run/current-system/sw/bin/cryptsetup status "$DRIVE_PARTLABEL_PRIMARY" \
    | grep device: | sed -n 's/^  device:  //p')
DRIVE_SECONDARY=$(/run/current-system/sw/bin/cryptsetup status "$DRIVE_PARTLABEL_SECONDARY" \
    | grep device: | sed -n 's/^  device:  //p')

printf "%s" "$KEY_OLD" > /tmp/luks-key-old
chmod 0400 /tmp/luks-key-old
printf "%s" "$KEY_NEW" > /tmp/luks-key-new
chmod 0400 /tmp/luks-key-new

/run/current-system/sw/bin/cryptsetup luksAddKey "$DRIVE_PRIMARY" --key-file /tmp/luks-key-old < /tmp/luks-key-new
/run/current-system/sw/bin/cryptsetup luksRemoveKey "$DRIVE_PRIMARY" --key-file /tmp/luks-key-old

if [ -n "$DRIVE_SECONDARY" ]; then
    /run/current-system/sw/cryptsetup luksAddKey "$DRIVE_SECONDARY" --key-file /tmp/luks-key-old < /tmp/luks-key-new
    /run/current-system/sw/cryptsetup luksRemoveKey "$DRIVE_SECONDARY" --key-file /tmp/luks-key-old
fi

rm -f /tmp/luks-key-old
rm -f /tmp/luks-key-new
