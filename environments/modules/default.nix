{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {

  options.aviary = {

    descriptionSecret = lib.mkOption {
      type = lib.types.str;
      default = "description";
      example = "user-description";
      description = "SOPS-Nix secret storing the user description";
    };
    
    graphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Graphical environment flag";
    };
    
    luksHashSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-luks-hash";
      example = "hostname-luks-hash";
      description = "SOPS-Nix secret storing the recovery hash for LUKS";
    };
    
    # This is state that should be stored on the system
    # and should be removed eventually.
    luksHashSecretPrevious = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-luks-hash-previous";
      example = "hostname-luks-hash-previous";
      description = "SOPS-Nix secret storing the previous recovery hash for LUKS";
    };

    passwordHashSecret = lib.mkOption {
      type = lib.types.str;
      default = "password-hash";
      example = "user-password-hash";
      description = "SOPS-Nix secret storing the user password hash";
    };

    # This is state that should be stored on the system
    # and should be removed eventually.
    passwordHashPreviousSecret = lib.mkOption {
      type = lib.types.str;
      default = "password-hash-previous";
      example = "user-password-hash-previous";
      description = "SOPS-Nix secret storing the user previous password hash";
    };

    sshAdminSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-admin";
      example = "hostname-ssh-admin";
      description = "SOPS-Nix secret storing the admin SSH private key";
    };

    sshAdminPubSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-admin-pub";
      example = "hostname-ssh-admin-pub";
      description = "SOPS-Nix secret storing the admin SSH public key";
    };

    sshUserSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-user";
      example = "hostname-ssh-user";
      description = "SOPS-Nix secret storing the user SSH private key";
    };

    secrets = {
      usernameSecret = lib.mkOption {
        type = lib.types.str;
        default = "username";
        example = "user-username";
        description = "SOPS-Nix secret storing the user username";
      };
    }; 
  };

  config = 
  
  let
    mapper =
      if builtins.pathExists /tmp/egg-drive-name
      then (builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name))
      else config.networking.hostName;

    primary = "disk-primary-luks-btrfs-" + mapper;
  
    secondary = "disk-secondary-luks-btrfs-" + mapper;

    cryptsetupGeneratorService = "systemd-cryptsetup@disk\\x2dprimary\\x2dluks\\x2dbtrfs\\x2d" + mapper;
  
    passwordHash =
      builtins.replaceStrings ["\n"] [""]
      (builtins.readFile config.sops.secrets."${config.aviary.passwordHashSecret}".path);
  
    passwordHashSalt = builtins.head (builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" passwordHash);
  
    luksHash =
      builtins.replaceStrings ["\n"] [""]
      (builtins.readFile config.sops.secrets."${config.aviary.luksHashSecret}".path);
  
    luksHashSalt = builtins.head (builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" luksHash);

    defaultPerms = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };

  in {

    documentation.doc.enable = false;
    nix.channel.enable = false; 
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nix.settings.trusted-users = ["root" "admin" "@wheel"];
    
    #hardware.enableAllFirmware = true;
    #nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # Used by nixd LSP server

    sops = {
      
      validateSopsFiles = false;
      age = {
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        keyFile = "/var/keys/age_host_key";
        generateKey = true;
      };
      
      secrets = {

        "${config.aviary.descriptionSecret}" = defaultPerms;
        
        "${config.aviary.luksHashSecret}" = defaultPerms;

        "${config.aviary.luksHashSecretPrevious}" = {
          restartUnits = ["syncluksrecovery.service"];
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
        }; 

        "${config.aviary.passwordHashSecret}" = defaultPerms;

        "${config.aviary.passwordHashPreviousSecret}" = {
          restartUnits = ["syncluks.service"];
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
        };

        "${config.aviary.sshAdminSecret}" = lib.mkForce {
          mode = "0400";
          owner = config.users.users."admin".name;
          group = "admin";
          path = "/home/admin/.ssh/id_ed25519";
        };

        "${config.aviary.sshAdminPubSecret}" = defaultPerms;
        
        "${config.aviary.sshUserSecret}" = lib.mkForce {
          mode = "0400";
          owner = config.users.users."1000".name;
          group = "admin";
          path = "/home/1000/.ssh/id_ed25519";
        };

        "${config.aviary.secrets.usernameSecret}" = defaultPerms;
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

    #security.tpm2.enable = true;

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

    security.sudo = {
      extraConfig = "Defaults lecture=never";
      extraRules = [
        {
          users = ["admin"];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
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

    networking = {
      useNetworkd = true;
      wireless.enable = true;
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

    programs = {
      nano.enable = false;
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      }; 
    }; 

    systemd.tmpfiles.rules = [
      "d /home/1000/.ssh 0700 ${config.users.users."1000".name} users -"
      "d /home/admin/.ssh 0700 admin admin -"
    ];

    systemd.services = {
      
      "syncluksrecovery" = {
        enable = true;
        description = "Syncronize luks recovery password";
        serviceConfig = {
          StandardOutput = "null";
          StandardError = "null";
        };

        script = ''
          oldKey=$(head -n1 ${config.sops.secrets."${config.aviary.luksHashSecretPrevious}".path})
          newKey=$(head -n1 ${config.sops.secrets."${config.aviary.luksHashSecret}".path})
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

      "syncluks" = {
        enable = true;
        description = "Syncronize luks passkey with user password";
        serviceConfig = {
          StandardOutput = "null";
          StandardError = "null";
        };

        script = ''
          oldKey=$(head -n1 ${config.sops.secrets."${config.aviary.passwordHashPreviousSecret}".path})
          newKey=$(head -n1 ${config.sops.secrets."${config.aviary.passwordHashSecret}".path})
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
    };

    users = {
      
      groups."admin" = { };
      mutableUsers = false;
      
      users =

      let
        username =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.secrets.usernameSecret}".path);
        description =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.descriptionSecret}".path);
        passwordHash =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.passwordHashSecret}".path);
        adminSSHPub =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.sshAdminPubSecret}".path);
    
      in {

        root = {
          description = lib.mkForce "root";
          openssh.authorizedKeys.keys = [adminSSHPub];
        };

        "admin" = {
          isSystemUser = true;
          description = "Admin";
          extraGroups = ["wheel"];
          group = "admin";
          useDefaultShell = true;
          home = "/home/admin";
          hashedPassword = passwordHash;
        };

        "1000" = {
          isNormalUser = true;
          name = username;
          description = description;
          uid = 1000;
          hashedPassword = passwordHash;
          home = "/home/1000";
        };
      };
    };

    home-manager = {
      extraSpecialArgs = {inherit inputs;};

      users."1000" = {
        home = {
          username = config.users.users."1000".name;
          homeDirectory = config.users.users."1000".home;
        };

        programs.home-manager.enable = true;
      };
    }; 
  };
}
