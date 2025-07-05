{
  config,
  lib,
  pkgs,
  ...
}: {
  options.sshinitrd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "enable ssh in initrd";
    };

    hostKey = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-host-initrd";
      example = "hostname-ssh-host-initrd";
      description = "hostkey secret name in sops-nix";
    };
  };

  config = lib.mkIf config.sshinitrd.enable {

    sops.secrets."${config.sshinitrd.hostKey}" = {}; 

    boot = {
      initrd = {
        availableKernelModules = [ "ccm" "ctr" ];

        network = {
          enable = true;
           
          ssh = {
            enable = true;
            ignoreEmptyHostKeys = true; # prevent error since we're deploying keys out of band
            extraConfig = "HostKey /etc/ssh/ssh_host_ed25519_key";
            port = 2222; # using a different port prevents ssh clients from throwing MITM error
            authorizedKeys = config.users.users."1000".openssh.authorizedKeys.keys;
          };
        };

        systemd = let
          mapper =
            if builtins.pathExists /tmp/egg-drive-name
            then builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name)
            else config.networking.hostName;
          cryptsetupGeneratorService = "systemd-cryptsetup@disk\\x2dprimary\\x2dluks\\x2dbtrfs\\x2d" + mapper;
        in {

          packages = [ pkgs.wpa_supplicant ];
          initrdBin = [ pkgs.wpa_supplicant ];

          users.root.shell = "/bin/systemd-tty-ask-password-agent";

          # Copy ssh host key into initrd. This has the unfortunate side effect of exposing
          # the key to all users on the system via nix store which is why we use a different
          # host key from the main system.
          tmpfiles.settings."10-ssh"."/etc/ssh/ssh_host_ed25519_key".f = let
            #content =
            #  builtins.replaceStrings ["\n"] ["\\n"]
            #  (builtins.readFile config.sops.secrets."${config.sshinitrd.hostKey}".path);
            content = builtins.readFile config.sops.secrets."${config.sshinitrd.hostKey}".path;
          in {
            group = "root";
            mode = "0400";
            user = "root";
            argument = content;
          };

          network.links."10-wifi" = {
            matchConfig.Type = "wlan";
            linkConfig.Name = "wifi0";
          };

          targets.cryptsetup.wants = [ "wpa_supplicant-initrd.service" ];

          services = {
            sshd.wantedBy = [ "systemd-ask-password-console.service" ];

            ${cryptsetupGeneratorService} = {
              after = [ "wpa_supplicant-initrd.service" ];
              requires = [ "wpa_supplicant-initrd.service" ];
            };

            "wpa_supplicant@".enable = false;

            "wpa_supplicant-initrd" = {
              description = "WPA supplicant daemon (for interface wifi0)";
              before = [ "network.target" ];
              #requires = [ "systemd-udevd.service" ];
              wants = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig.Type = "simple";
              script = ''
                if [ -e "/run/systemd/tpm2-srk-public-key.pem" ]; then
                    echo "TPM present, stopping script"
                    exit 0
                fi

                if [ ! -e "/sys/class/net/wifi0" ]; then
                    echo "No wifi device present, stopping script"
                    exit 0
                fi

                wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-wifi0.conf -i wifi0
              '';

              preStart = ''
                connection="no"
                pidfile="/var/run/wpa_supplicant-wifi0.pid"
                confile="/etc/wpa_supplicant/wpa_supplicant-wifi0.conf"
                ssid=""

                sleep 5

                if [ -e "/run/systemd/tpm2-srk-public-key.pem" ]; then
                    echo "TPM present, stopping pre-start script"
                    exit 0
                fi

                if [ ! -e "/sys/class/net/wifi0" ]; then
                    echo "No wifi device present, stopping pre-start script"
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
              '';

              unitConfig.DefaultDependencies = false;
              unitConfig.IgnoreOnFailure = "yes";
              serviceConfig.TimeoutStartSec = 0;
            };
          };
        };
      };
    };
  };
}
