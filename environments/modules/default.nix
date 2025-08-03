{
  config,
  inputs,
  lib,
  pkgs,
  utils,
  ...
}:

let

  inherit ( builtins )
    head
    match
    readFile
  ;
  
  inherit ( lib )
    foldl'
    listToAttrs
    mkForce
    mkIf
    mkOption
    nameValuePair
    optional
    sortOn
  ;

  inherit ( lib.attrsets )
    attrsToList
  ;

  inherit ( lib.types )
    bool
    nullOr
    str
  ;

  inherit ( pkgs )
    writeShellScript
  ;

  inherit ( utils )
    escapeSystemdPath
  ;

  host = config.networking.hostName;

  pcr15 = config.aviary.pcr15;

in {

  options.aviary = { 
    
    graphical = mkOption {
      type = bool;
      default = false;
      example = true;
      description = "Graphical environment flag";
    };

    # All credit for cryptsetup pcr15 check goes to patrick
    # https://forge.lel.lol/patrick/nix-config/src/branch/master/modules/ensure-pcr.nix
    pcr15 = mkOption {
      type = nullOr str;
      default = null;
      example = "6214de8c3d861c4b451acc8c4e24294c95d55bcec516bbf15c077ca3bffb6547";
      description = ''
        The expected value of PCR 15 after all luks partitions have been unlocked
        Should be a 64 character hex string as ouput by the sha256 field of
        'systemd-analyze pcrs 15 --json=short'
        If set to null (the default) it will not check the value.
        If the check fails the boot will abort and you will be dropped into an 
        emergency shell, if enabled.
        In ermergency shell type:
        'systemctl disable check-pcrs'
        'systemctl default'
        to continue booting
      ''; 
    };

    secrets = {

      description = mkOption {
        type = str;
        default = "description";
        example = "Username";
        description = "SOPS-Nix secret storing the user description";
      };

      luksHash = mkOption {
        type = str;
        default = host + "-luks-hash";
        example = "hostname-luks-hash";
        description = "SOPS-Nix secret storing the recovery hash for LUKS";
      }; 

      passwordHash = mkOption {
        type = str;
        default = "password-hash";
        example = "user-password-hash";
        description = "SOPS-Nix secret storing the user password hash";
      };

      platform = mkOption {
        type = str;
        default = host + "-platform";
        example = "hostname-platform";
        description = "SOPS-Nix secret storing the system platform";
      };

      stateVersion = mkOption {
        type = str;
        default = host + "-state-version";
        example = "hostname-state-version";
        description = "SOPS-Nix secret storing the system stateversion";
      };

      sshAdmin = mkOption {
        type = str;
        default = host + "-ssh-admin";
        example = "hostname-ssh-admin";
        description = "SOPS-Nix secret storing the admin SSH private key";
      };

      sshAdminPub = mkOption {
        type = str;
        default = host + "-ssh-admin-pub";
        example = "hostname-ssh-admin-pub";
        description = "SOPS-Nix secret storing the admin SSH public key";
      };

      sshUser = mkOption {
        type = str;
        default = host + "-ssh-user";
        example = "hostname-ssh-user";
        description = "SOPS-Nix secret storing the user SSH private key";
      };

      timezone = mkOption {
        type = str;
        default = host + "-timezone";
        example = "hostname-timezone";
        description = "SOPS-Nix secrets storing the system timezone";
      };

      username = mkOption {
        type = str;
        default = "username";
        example = "user-username";
        description = "SOPS-Nix secret storing the user username";
      };
    }; 
  };

  config = 
  
  let

    deviceMapperPrimary = "disk-primary-luks-btrfs-" + host; 
    deviceMapperSecondary = "disk-secondary-luks-btrfs-" + host;  

    secrets = config.sops.secrets;
    secretsName = config.aviary.secrets;

    defaultPermissions = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };

  in {

    #nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # Used by nixd LSP server

    documentation.doc.enable = false;
    nix.channel.enable = false;
    nixpkgs.config.allowUnfree = true;
    nixpkgs.hostPlatform = readFile secrets."${secretsName.platform}".path;
    hardware.enableAllFirmware = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.trusted-users = [ "root" "admin" "@wheel" ];

    sops = {
      
      validateSopsFiles = false;
      age = {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/var/keys/age_host_key";
        generateKey = true;
      };
      
      secrets = {

        "${secretsName.description}" = defaultPermissions;
        "${secretsName.platform}" = defaultPermissions;
        "${secretsName.stateVersion}" = defaultPermissions;
        "${secretsName.sshAdminPub}" = defaultPermissions;
        "${secretsName.timezone}" = defaultPermissions;
        "${secretsName.username}" = defaultPermissions;

        "${secretsName.sshAdmin}" = mkForce {
          mode = "0400";
          owner = config.users.users."admin".name;
          group = "admin";
          path = "/home/admin/.ssh/id_ed25519";
        }; 
        
        "${secretsName.sshUser}" = mkForce {
          mode = "0400";
          owner = config.users.users."1000".name;
          group = "admin";
          path = "/home/1000/.ssh/id_ed25519";
        };

        "${secretsName.luksHash}" = {
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
          restartUnits = [ "syncluksrecovery.service" ];
        };

        "${secretsName.passwordHash}" = {
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
          restartUnits = [ "syncluks.service" ];
        };
      };
    };

    system.stateVersion = readFile secrets."${secretsName.stateVersion}".path;

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

    boot.initrd.systemd = 

    let

      cryptsetupExecStart = writeShellScript "cryptsetup" (
        readFile ../../scripts/systemd/cryptsetup.sh
      );

      cryptsetupExecStartPost = writeShellScript "impermanence" (
        readFile ../../scripts/systemd/impermanence.sh
      );

      cryptsetupEarlyExecStart = writeShellScript "cryptsetup-early" (
        readFile ../../scripts/systemd/cryptsetupEarly.sh
      );

      pcrExecStart = writeShellScript "pcr15check" (
        readFile ../../scripts/systemd/pcr15check.sh
      );

      deviceDiskPrimary = "disk-primary-luks-${host}";
      deviceDiskSecondary = "disk-secondary-luks-${host}";          

      systemdPath = config.boot.initrd.systemd.package;

      regex = "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$";

      saltPassword = head (
        match regex (
          readFile secrets."${secretsName.passwordHash}".path
        )
      );
  
      saltRecovery = head (
        match regex (
          readFile secrets."${secretsName.luksHash}".path
        )
      );

    in {

      packages = with pkgs; [ mkpasswd ];
      initrdBin = with pkgs; [ mkpasswd ];

      services = {

        systemd-ask-password-console.wantedBy = [ "cryptsetup.target" ]; 

        "check-pcrs" = mkIf ( pcr15 != null ) { 
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pcrExecStart} ${pcr15}";
          };
          unitConfig.DefaultDependencies = "no";
          after = [ "cryptsetup.target" ];
          before = [ "sysroot.mount" ];
          requiredBy = [ "sysroot.mount" ];
        };

        "systemd-cryptsetup-early" = {
          unitConfig = {
            Description = "Early cryptography setup for ${deviceMapperPrimary}";
            DefaultDependencies = "no";
            IgnoreOnIsolate = true;
            Conflicts = [ "umount.target" ];
            BindsTo = [ "dev-disk-${escapeSystemdPath "by-partlabel"}-${escapeSystemdPath deviceDiskPrimary}.device" ];
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutSec = "infinity";
            KeyringMode = "shared";
            OOMScoreAdjust = 500;
            ImportCredential = "cryptsetup.*";
            ExecStart = "${cryptsetupEarlyExecStart} ${systemdPath} ${deviceMapperPrimary} ${deviceDiskPrimary} discard,headless,tpm2-device=auto,tpm2-measure-pcr=yes";
          }; 
          after = [
            "cryptsetup-pre.target"
            "systemd-udevd-kernel.socket"
            "dev-disk-${escapeSystemdPath "by-partlabel"}-${escapeSystemdPath deviceDiskPrimary}.device"
          ]
          ++ ( optional config.boot.initrd.systemd.tpm2.enable "systemd-tpm2-setup-early.service" );
          before = [
            "blockdev@dev-mapper-${deviceMapperPrimary}.target"
            "cryptsetup.target"
            "umount.target"
            "wpa_supplicant-initrd.service"
          ];
          wants = [ "blockdev@dev-mapper-${deviceMapperPrimary}.target" ];
          requiredBy = [ "sysroot.mount" "wpa_supplicant-initrd.service" ];
        };
      }
      // ( listToAttrs (
        foldl' (
          acc: attrs:
          [
            ( nameValuePair "systemd-cryptsetup@${escapeSystemdPath attrs.name}" {
                overrideStrategy = "asDropin";
                serviceConfig = {
                  
                  ExecStart = [
                    ""
                    "${cryptsetupExecStart} ${systemdPath} ${attrs.name} ${attrs.value.device} discard,headless \$${saltPassword} \$${saltRecovery}"
                  ];

                  ExecStartPost = if ( "${attrs.name}" == "${deviceMapperPrimary}" ) then
                    "${cryptsetupExecStartPost} ${attrs.name}"
                  else "";
                };

                after = [
                  "wpa_supplicant-initrd.service"
                ] ++ optional ( acc != [ ] ) "${( head acc ).name}.service";

                requires = [ "wpa_supplicant-initrd.service" ];

                wants = [ "network-online.target" ];
              }
            )
          ]
          ++ acc
        ) [ ] ( sortOn ( x: x.name ) ( attrsToList config.boot.initrd.luks.devices ) )
      ));

      storePaths = [
        cryptsetupExecStart
        cryptsetupExecStartPost
        cryptsetupEarlyExecStart
        pcrExecStart
      ];
    };

    security.sudo = {
      
      extraConfig = "Defaults lecture=never";
      
      extraRules = [
        
        {
          users = [ "admin" ];
          commands = [
            
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
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

    time.timeZone = readFile secrets."${secretsName.timezone}".path;

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

      # No longer works
      /*
      (lib.hiPrio (pkgs.runCommand "nvim.desktop-hide" {} ''
        mkdir -p "$out/share/applications"
        cat "${config.programs.neovim.finalPackage}/share/applications/nvim.desktop" \
          > "$out/share/applications/nvim.desktop"
        echo "Hidden=1" >> "$out/share/applications/nvim.desktop"
      ''))
      */
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

    systemd = {
      
      tmpfiles.rules = [
        "d /home/1000/.ssh 0700 ${config.users.users."1000".name} users -"
        "d /home/admin/.ssh 0700 admin admin -"
      ];

      services =
      
      let
        
        syncluksExecStart = writeShellScript "syncluks" (
          readFile ../../scripts/systemd/syncluks.sh
        );

      in {

        "syncluks" = {
          enable = true;
          description = "Syncronize LUKS password with user password";
          serviceConfig =
          
          let 

            hashPathNew = secrets."${secretsName.passwordHash}".path; 
          
          in {

            ExecStart = "${syncluksExecStart} ${hashPathNew} ${deviceMapperPrimary} ${deviceMapperSecondary}";
            StandardError = "null";
            StandardOutput = "null"; 
            Type = "oneshot"; 
          };
        };
      
        "syncluksrecovery" = {
          enable = true;
          description = "Syncronize LUKS recovery password";
          serviceConfig =
          
          let

            hashPathNew = secrets."${secretsName.luksHash}".path; 
          
          in {

            ExecStart = "${syncluksExecStart} ${hashPathNew} ${deviceMapperPrimary} ${deviceMapperSecondary}";
            StandardError = "null";
            StandardOutput = "null"; 
            Type = "oneshot";
          };
        }; 
      };
    };

    users = {
      
      groups."admin" = { };
      mutableUsers = false;
      
      users =

      let
         
        username = readFile secrets."${secretsName.username}".path;
        description = readFile secrets."${secretsName.description}".path;
        passwordHash = readFile secrets."${secretsName.passwordHash}".path;
        adminSSHPub = readFile secrets."${secretsName.sshAdminPub}".path;
    
      in {

        root = {
          description = mkForce "root";
          openssh.authorizedKeys.keys = [ adminSSHPub ];
        };

        "admin" = {
          isSystemUser = true;
          description = "Admin";
          extraGroups = [ "wheel" ];
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
      
      extraSpecialArgs = { inherit inputs; };

      users."1000" = {
       
        home = {
          homeDirectory = config.users.users."1000".home;
          stateVersion = config.system.stateVersion;
          username = config.users.users."1000".name; 
        };

        programs.home-manager.enable = true;
      };
    }; 
  };
}
