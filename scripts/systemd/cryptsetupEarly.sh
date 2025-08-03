#!/bin/sh

systemd_path=$1
device_mapper=$2
device_disk=$3
flags=$4

succeed="true"

("$systemd_path"/bin/systemd-cryptsetup attach "$device_mapper" /dev/disk/by-partlabel/"$device_disk" - "$flags") || (succeed="false")

if [ "$succeed" = "true" ]; then
    if plymouth --ping || false; then
        plymouth display-message --text="Unlocking drive automatically failed. Proceeding to manual decryption."
        sleep 1
        plymouth display-message --text="Unlocking drive automatically failed. Proceeding to manual decryption.."
        sleep 1
        plymouth display-message --text="Unlocking drive automatically failed. Proceeding to manual decryption..."
        sleep 1
        plymouth display-message --text=""
    else
        echo -e -n "[AVIARY] \e[1mUnlocking drive automatically failed. Proceeding to manual decryption.\e[0m\r" > /dev/console
        sleep 1
        echo -e -n "[AVIARY] \e[1mUnlocking drive automatically failed. Proceeding to manual decryption..\e[0m\r" > /dev/console
        sleep 1
        echo -e -n "[AVIARY] \e[1mUnlocking drive automatically failed. Proceeding to manual decryption...\e[0m\n" > /dev/console
        sleep 1
    fi
fi
