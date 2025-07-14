#!/bin/sh

mapper_device=$1

delete_subvolume_recursively() {
    IFS=$'\n'
    for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
    done
    btrfs subvolume delete "$1"
}

mkdir /btrfs_tmp
mount /dev/mapper/"$mapper_device" /btrfs_tmp

if [[ -e /btrfs_tmp/root ]]; then
    mkdir -p /btrfs_tmp/old_roots
    timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
    mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
fi

for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +14); do
    delete_subvolume_recursively "$i"
done

btrfs subvolume create /btrfs_tmp/root

# Hand off recovery wifi credentials
if [[ -e "/btrfs_tmp/persist/wpa_supplicant-wifi0.conf" ]]; then
    rm /btrfs_tmp/persist/wpa_supplicant-wifi0.conf
fi
if [[ -e "/etc/wpa_supplicant/wpa_supplicant-wifi0.conf" ]]; then
    cp /etc/wpa_supplicant/wpa_supplicant-wifi0.conf /btrfs_tmp/persist/wpa_supplicant-wifi0.conf
fi

umount /btrfs_tmp
echo "Impermanence completed successfully!";
