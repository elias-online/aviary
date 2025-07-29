#!/bin/sh

mapper_device=$1

connection="no"
pidfile="/var/run/wpa_supplicant-wifi0.pid"
confile="/etc/wpa_supplicant/wpa_supplicant-wifi0.conf"
ssid=""

if [ -e "/dev/mapper/$mapper_device" ]; then
    echo "Mapper device already unlocked with TPM, exiting..."
    exit 0
fi

sleep 5

if [ ! -e "/sys/class/net/wifi0" ]; then
    echo "No wifi device present, stopping pre-start script..."
    exit 0
fi

sleep 5

while read -r line; do
    if [[ "$line" == *ether* && "$line" == *routable* ]]; then
        if plymouth --ping || false; then
            plymouth display-message --text="Wired connection established, stopping Wi-Fi setup."
            sleep 1
            plymouth display-message --text="Wired connection established, stopping Wi-Fi setup.."
            sleep 1
            plymouth display-message --text="Wired connection established, stopping Wi-Fi setup..."
            sleep 1
            plymouth display-message --text=""
        else
            echo "Wired connection established, stopping Wi-Fi setup..." > /dev/console
        fi
        exit 0
    fi
done < <(networkctl list --no-pager)

while [[ "$connection" == "no" ]]; do
    setupwifi=""
    if plymouth --ping || false; then
        tmpFile="/run/plymouth-wifi-input"
        rm -f "$tmpFile"
        plymouth display-message --text="Connect to Wi-Fi [ y/N ]"

        (
            setupwifi=$(plymouth watch-keystroke --keys="yYnN")
            echo "$setupwifi" > "$tmpFile"
        ) &

        pid=$1
        elapsed=0
        while [ $elapsed -lt 20 ]; do
            if [ -s "$tmpFile" ]; then
                setupwifi=$(cat "$tmpFile")
                kill "$pid" 2>/dev/null || true
                break
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done

        plymouth display-message --text=""
        if [ ! -s "$tmpFile" ]; then
            kill "$pid" 2>/dev/null || true
        fi
    else
        setupwifi=$(systemd-ask-password -e --timeout=20 --no-tty "Connect to Wi-Fi [ y/N ]" || true)
    fi
    if [[ "$setupwifi" != "y" && "$setupwifi" != "Y" ]]; then
        exit 0
    fi

    if plymouth --ping || false; then
        ssid=$(plymouth ask-question --prompt="Enter Wi-Fi name")
    else
        ssid=$(systemd-ask-password -e --timeout=0 --no-tty "Enter Wi-Fi name:")
    fi

    psk=""
    while [[ $(expr length "$psk") -lt 8 || $(expr length "$psk") -gt 63 ]]; do
        if plymouth --ping || false; then
            psk=$(systemd-ask-password -e --timeout=0 --no-tty "Enter Wi-Fi password")
        else
            psk=$(systemd-ask-password -e --timeout=0 --no-tty "Enter Wi-Fi password:")
        fi
    done

    mkdir -p /etc/wpa_supplicant
    rm -f "$confile"
    touch "$confile"
    echo "country=US" >> "$confile"
    wpa_passphrase "$ssid" "$psk" >> "$confile"

    rm -f "$pidfile"
    wpa_supplicant -B -c "$confile" -i wifi0 -P "$pidfile"

    sleep 10
    while read -r line; do
        if [[ "$line" == *wifi0* && "$line" == *routable* ]]; then
            connection="yes"
            break
        fi
    done < <(networkctl list --no-pager)

    if [[ "$connection" == "no" ]]; then
        if plymouth --ping || false; then
            plymouth display-message --text="Failed to connect to Wi-Fi..."
            sleep 3
            plymouth display-message --text=""
        else
            echo "Failed to connect to Wi-Fi..." > /dev/console
        fi
    fi

    kill "$(cat "$pidfile")"
done
