{
  config,
  #inputs,
  lib,
  pkgs,
  ...
}: let
  mapper =
    if builtins.pathExists /tmp/egg-drive-name
    then (builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name))
    else config.networking.hostName;
  cryptsetupGeneratorService = "systemd-cryptsetup@disk\\x2dprimary\\x2dluks\\x2dbtrfs\\x2d" + mapper;
  passwordHash =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."${config.usersbase.passwordHashSecret}".path);
  passwordHashSalt = builtins.head (builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" passwordHash);
  luksHash =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."${config.default.luksHashSecret}".path);
  luksHashSalt = builtins.head (builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" luksHash);
  primary = "disk-primary-luks-btrfs-" + mapper;
  secondary = "disk-secondary-luks-btrfs-" + mapper;
in {
  options.default = {
    graphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "whether or not the environment is graphical";
    };
    luksHashSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-luks-hash";
      example = "hostname-luks-hash";
      description = "luks recovery hash secrets name in sops-nix";
    };
    luksHashSecretPrevious = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-luks-hash-previous";
      example = "hostname-luks-hash-previous";
      description = "luks recovery hash previous secrets name in sops-nix";
    };
  };

  config = {
    sops = {
      validateSopsFiles = false;
      age = {
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        keyFile = "/var/keys/age_host_key";
        generateKey = true;
      };
      secrets = {
        "${config.default.luksHashSecret}" = {
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
        };
        "${config.default.luksHashSecretPrevious}" = {
          restartUnits = ["syncluksrecovery.service"];
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
        };
      };
    };

    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
    };

    security.tpm2.enable = true;

    boot.initrd.systemd = {

      packages = with pkgs; [mkpasswd];
      initrdBin = with pkgs; [mkpasswd];

      services = {

        systemd-ask-password-console.wantedBy = ["cryptsetup.target"];

        ${cryptsetupGeneratorService} = {
          enable = true;
          overrideStrategy = "asDropin";
          
          serviceConfig = {

            # Explicity overwrite generated unit's ExecStart to run systemd-cryptsetup
            # in headless mode to prevent password fallback as Disko settings.fallbackToPassword = false
            # doesn't appear to properly configure /etc/crypttab in initrd
            ExecStart = [
              ""
              "systemd-cryptsetup attach 'disk-primary-luks-btrfs-${mapper}' '/dev/disk/by-partlabel/disk-primary-luks-${mapper}' '/luks-key' 'discard,headless'"
            ];
          };
          
          unitConfig.DefaultDependencies = "no";

          
          preStart = ''

            #if [ -e "/run/systemd/tpm2-srk-public-key.pem" ]; then
            #    exit 0
            #fi

            passwordHash=""
            luksHash=""
            while [[ "$passwordHash" != '${passwordHash}' && "$luksHash" != '${luksHash}' ]]; do
                sleep 3
                if plymouth --ping || false; then
                    password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system")
                else
                    password=$(systemd-ask-password --timeout=0 --no-tty "Enter passphrase for system:")
                fi
                
                # REMOVE ME
                if [[ "$password" == "none" ]]; then
                    break
                fi

                passwordHash=$(mkpasswd --method=yescrypt --salt='${passwordHashSalt}' "$password")
                luksHash=$(mkpasswd --method=yescrypt --salt='${luksHashSalt}' "$password")
            done

            rm -f /luks-key
            printf "%s" "$passwordHash" > /luks-key
            chmod 0400 /luks-key

            rm -f /luks-key-recovery
            printf "%s" "$luksHash" > /luks-key-recovery
            chmod 0400 /luks-key-recovery

            echo "Hash completed successfully!";
          '';
          
          postStart = ''
            delete_subvolume_recursively() {
                IFS=$'\n'
                for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                    delete_subvolume_recursively "/btrfs_tmp/$i"
                done
                btrfs subvolume delete "$1"
            }

            luksdevice="/dev/mapper/disk-primary-luks-btrfs-${mapper}"
          
            mkdir /btrfs_tmp
            mount "$luksdevice" /btrfs_tmp

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
          '';
        };
      };
    };

    systemd.services."syncluksrecovery" = {
      enable = true;
      description = "Syncronize luks recovery password";
      serviceConfig = {
        StandardOutput = "null";
        StandardError = "null";
      };

      script = ''
        oldKey=$(head -n1 ${config.sops.secrets."${config.default.luksHashSecretPrevious}".path})
        newKey=$(head -n1 ${config.sops.secrets."${config.default.luksHashSecret}".path})
        primaryDevice=$(/run/current-system/sw/bin/cryptsetup status "${primary}" \
            | grep device: | sed -n 's/^  device:  //p')
        secondaryDevice=$(/run/current-system/sw/bin/cryptsetup status "${secondary}" \
            | grep device: | sed -n 's/^  device:  //p')

        printf "%s" "$oldKey" > /tmp/luks-key-old
        chmod 0400 /tmp/luks-key-old
        printf "%s" "$newKey" > /tmp/luks-key-new
        chmod 0400 /tmp/luks-key-new

        /run/current-system/sw/bin/cryptsetup luksAddKey "$primaryDevice" --key-file /tmp/luks-key-old < /tmp/luks-key-new
        /run/current-system/sw/bin/cryptsetup luksRemoveKey "$primaryDevice" --key-file /tmp/luks-key-old

        if [ -n "$secondaryDevice" ]; then
            /run/current-system/sw/cryptsetup luksAddKey "$secondaryDevice" --key-file /tmp/luks-key-old < /tmp/luks-key-new
            /run/current-system/sw/cryptsetup luksRemoveKey "$secondaryDevice" --key-file /tmp/luks-key-old
        fi

        rm -f /tmp/luks-key-old
        rm -f /tmp/luks-key-new
      '';

      serviceConfig.Type = "oneshot";
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    environment.systemPackages = [
      pkgs.age
      pkgs.disko
      pkgs.efitools
      pkgs.git
      pkgs.jq
      pkgs.linux-firmware
      pkgs.nixos-anywhere
      pkgs.rsync
      pkgs.sbctl
      pkgs.sbsigntool
      pkgs.sops
      pkgs.ssh-to-age

      (lib.hiPrio (pkgs.runCommand "nvim.desktop-hide" {} ''
        mkdir -p "$out/share/applications"
        cat "${config.programs.neovim.finalPackage}/share/applications/nvim.desktop" \
          > "$out/share/applications/nvim.desktop"
        echo "Hidden=1" >> "$out/share/applications/nvim.desktop"
      ''))
    ];

    networking.useNetworkd = true;
    networking.wireless.enable = true;

    programs = {
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      nano.enable = false;
    };

    security.sudo.extraConfig = "Defaults lecture=never";

    documentation.doc.enable = false;
    nix.channel.enable = false;
    #nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # Used by nixd LSP server
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nix.settings.trusted-users = ["root" "admin" "@wheel"];
    #hardware.enableAllFirmware = true;
    users.mutableUsers = false;
  };
}
