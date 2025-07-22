{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {

  options.aviary = { 
    
    graphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Graphical environment flag";
    }; 

    secrets = {

      description = lib.mkOption {
        type = lib.types.str;
        default = "description";
        example = "user-description";
        description = "SOPS-Nix secret storing the user description";
      };

      luksHash = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName + "-luks-hash";
        example = "hostname-luks-hash";
        description = "SOPS-Nix secret storing the recovery hash for LUKS";
      };
    
      # This is state that should be stored on the system
      # and should be removed eventually.
      luksHashPrevious = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName + "-luks-hash-previous";
        example = "hostname-luks-hash-previous";
        description = "SOPS-Nix secret storing the previous recovery hash for LUKS";
      };

      passwordHash = lib.mkOption {
        type = lib.types.str;
        default = "password-hash";
        example = "user-password-hash";
        description = "SOPS-Nix secret storing the user password hash";
      };

      # This is state that should be stored on the system
      # and should be removed eventually.
      passwordHashPrevious = lib.mkOption {
        type = lib.types.str;
        default = "password-hash-previous";
        example = "user-password-hash-previous";
        description = "SOPS-Nix secret storing the user previous password hash";
      };

      sshAdmin = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName + "-ssh-admin";
        example = "hostname-ssh-admin";
        description = "SOPS-Nix secret storing the admin SSH private key";
      };

      sshAdminPub = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName + "-ssh-admin-pub";
        example = "hostname-ssh-admin-pub";
        description = "SOPS-Nix secret storing the admin SSH public key";
      };

      sshUser = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName + "-ssh-user";
        example = "hostname-ssh-user";
        description = "SOPS-Nix secret storing the user SSH private key";
      };

      username = lib.mkOption {
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
      (builtins.readFile config.sops.secrets."${config.aviary.secrets.passwordHash}".path);
  
    #passwordHashSalt = builtins.head (builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" passwordHash);
  
    luksHash =
      builtins.replaceStrings ["\n"] [""]
      (builtins.readFile config.sops.secrets."${config.aviary.secrets.luksHash}".path);
  
    #luksHashSalt = builtins.head (builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" luksHash);

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

        "${config.aviary.secrets.description}" = defaultPerms;
        
        "${config.aviary.secrets.luksHash}" = defaultPerms;

        "${config.aviary.secrets.luksHashPrevious}" = {
          restartUnits = ["syncluksrecovery.service"];
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
        }; 

        "${config.aviary.secrets.passwordHash}" = defaultPerms;

        "${config.aviary.secrets.passwordHashPrevious}" = {
          restartUnits = ["syncluks.service"];
          mode = "0440";
          owner = config.users.users."1000".name;
          group = "admin";
        };

        "${config.aviary.secrets.sshAdmin}" = lib.mkForce {
          mode = "0400";
          owner = config.users.users."admin".name;
          group = "admin";
          path = "/home/admin/.ssh/id_ed25519";
        };

        "${config.aviary.secrets.sshAdminPub}" = defaultPerms;
        
        "${config.aviary.secrets.sshUser}" = lib.mkForce {
          mode = "0400";
          owner = config.users.users."1000".name;
          group = "admin";
          path = "/home/1000/.ssh/id_ed25519";
        };

        "${config.aviary.secrets.username}" = defaultPerms;
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

    boot.initrd.systemd = 

    let
      cryptExecStartPre = (pkgs.writeShellScript "cryptpwd" ''${ builtins.readFile ../../scripts/systemd/cryptpwd.sh }'');
      cryptExecStart = (pkgs.writeShellScript "cryptattach" ''${ builtins.readFile ../../scripts/systemd/cryptattach.sh }'');
      cryptExecStartPost = (pkgs.writeShellScript "impermanence" ''${ builtins.readFile ../../scripts/systemd/impermanence.sh }'');
      cryptStop = (pkgs.writeShellScript "cryptdetach" ''${ builtins.readFile ../../scripts/systemd/cryptdetach.sh }'');
      diskDevice = "disk-primary-luks-${mapper}";
      mapperDevice = "disk-primary-luks-btrfs-${mapper}";
    in {

      packages = with pkgs; [mkpasswd];
      initrdBin = with pkgs; [mkpasswd];

      services = {

        systemd-ask-password-console.wantedBy = ["cryptsetup.target"];

        "systemd-cryptsetup-1" = {
          enable = true;
          description = "Cryptography Setup 1 for ${mapperDevice}";
          serviceConfig = {
            ExecStartPre = "${cryptExecStartPre} ${mapperDevice}";
            ExecStart = "${cryptExecStart} ${mapperDevice} ${diskDevice}";
            ExecStop = "${cryptStop} ${mapperDevice}";
            ImportCredential = "cryptsetup.*";
            KeyringMode = "shared";
            OOMScoreAdjust = 500;
            RemainAfterExit = "yes";
            TimeoutSec = "infinity";
            Type = "oneshot";
          };
          unitConfig = {
            DefaultDependencies = "no";
            IgnoreOnIsolate = "true"; 
            RequiresMountsFor = "/luks-key";
            SourcePath = "/etc/crypttab"; 
            After = [
              "cryptsetup-pre.target"
              "dev-disk-by\x2dpartlabel-disk\x2dprimary\x2dluks\x2d${mapper}.device"
              "systemd-tpm2-setup-early.service"
              "systemd-udevd-kernel.socket"
              "wpa_supplicant-initrd.service"
            ];
            Before = [
              "cryptsetup.target"
              "blockdev@dev-mapper-${mapperDevice}.target"
              "umount.target"
            ];
            BindsTo = [
              "dev-disk-by\x2dpartlabel-disk\x2dprimary\x2dluks\x2d${mapper}.device"
            ];
            Conflicts = [
              "umount.target"
            ]; 
            Requires = [
              "wpa_supplicant-initrd.service"
            ];
            Wants = [
              "blockdev@dev-mapper-${mapperDevice}.target"
              "network-online.target"
            ]; 
          }; 
        };

        "systemd-cryptsetup-2" = {
          enable = true;
          description = "Cryptography Setup 2 for ${mapperDevice}";
          serviceConfig = {
            ExecStartPre = "${cryptExecStartPre} ${mapperDevice}";
            ExecStart = "${cryptExecStart} ${mapperDevice} ${diskDevice}";
            ExecStop = "${cryptStop} ${mapperDevice}";
            ImportCredential = "cryptsetup.*";
            KeyringMode = "shared";
            OOMScoreAdjust = 500;
            RemainAfterExit = "yes";
            TimeoutSec = "infinity";
            Type = "oneshot";
          };
          unitConfig = {
            DefaultDependencies = "no";
            IgnoreOnIsolate = "true"; 
            RequiresMountsFor = "/luks-key";
            SourcePath = "/etc/crypttab"; 
            After = [
              "cryptsetup-pre.target"
              "dev-disk-by\x2dpartlabel-disk\x2dprimary\x2dluks\x2d${mapper}.device"
              "systemd-cryptsetup-1.service"
              "systemd-tpm2-setup-early.service"
              "systemd-udevd-kernel.socket" 
              "wpa_supplicant-initrd.service"
            ];
            Before = [
              "cryptsetup.target"
              "blockdev@dev-mapper-${mapperDevice}.target"
              "umount.target"
            ];
            BindsTo = [
              "dev-disk-by\x2dpartlabel-disk\x2dprimary\x2dluks\x2d${mapper}.device"
            ];
            Conflicts = [
              "umount.target"
            ]; 
            Requires = [
              "systemd-cryptsetup-1.service"
              "wpa_supplicant-initrd.service"
            ];
            Wants = [
              "blockdev@dev-mapper-${mapperDevice}.target"
              "network-online.target"
            ]; 
          };
        };

        "systemd-cryptsetup-3" = {
          enable = true;
          description = "Cryptography Setup 3 for ${mapperDevice}";
          serviceConfig = {
            ExecStartPre = "${cryptExecStartPre} ${mapperDevice}";
            ExecStart = "${cryptExecStart} ${mapperDevice} ${diskDevice}";
            ExecStop = "${cryptStop} ${mapperDevice}";
            ImportCredential = "cryptsetup.*";
            KeyringMode = "shared";
            OOMScoreAdjust = 500;
            RemainAfterExit = "yes";
            TimeoutSec = "infinity";
            Type = "oneshot";
          };
          unitConfig = {
            DefaultDependencies = "no";
            IgnoreOnIsolate = "true"; 
            RequiresMountsFor = "/luks-key";
            SourcePath = "/etc/crypttab"; 
            After = [
              "cryptsetup-pre.target"
              "dev-disk-by\x2dpartlabel-disk\x2dprimary\x2dluks\x2d${mapper}.device"
              "systemd-cryptsetup-2.service"
              "systemd-tpm2-setup-early.service"
              "systemd-udevd-kernel.socket" 
              "wpa_supplicant-initrd.service"
            ];
            Before = [
              "cryptsetup.target"
              "blockdev@dev-mapper-${mapperDevice}.target"
              "umount.target"
            ];
            BindsTo = [
              "dev-disk-by\x2dpartlabel-disk\x2dprimary\x2dluks\x2d${mapper}.device"
            ];
            Conflicts = [
              "umount.target"
            ]; 
            Requires = [
              "systemd-cryptsetup-3.service"
              "wpa_supplicant-initrd.service"
            ];
            Wants = [
              "blockdev@dev-mapper-${mapperDevice}.target"
              "network-online.target"
            ]; 
          };
        };

        ${cryptsetupGeneratorService} = {
          enable = true;
          overrideStrategy = "asDropin";
          serviceConfig.ExecStart = [ "" "true" ];
          serviceConfig.ExecStartPost = "${cryptExecStartPost} ${mapperDevice}";
          serviceConfig.ExecStop = [ "" "" ];
          unitConfig.DefaultDependencies = "no";
          unitConfig.After = [ "systemd-cryptsetup-3.service" ];
          unitConfig.Requires = [ "systemd-cryptsetup-3.service" ];
        };
      };

      storePaths = [
        cryptExecStartPre
        cryptExecStartPost
      ];
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

    systemd = {
      
      tmpfiles.rules = [
        "d /home/1000/.ssh 0700 ${config.users.users."1000".name} users -"
        "d /home/admin/.ssh 0700 admin admin -"
      ];

      services =
      
      let
        execStart = (pkgs.writeShellScript "syncluks" ''${ builtins.readFile ../../scripts/systemd/syncluks.sh }'');
        drivePartlabelPrimary = primary;
        drivePartlabelSecondary = secondary;
      in {

        "syncluks" = {
          enable = true;
          description = "Syncronize LUKS password with user password";
          serviceConfig =
          
          let 
            hashPathOld = config.sops.secrets."${config.aviary.secrets.passwordHashPrevious}".path;
            hashPathNew = config.sops.secrets."${config.aviary.secrets.passwordHash}".path; 
          in {

            ExecStart = "${execStart} ${hashPathOld} ${hashPathNew} ${drivePartlabelPrimary} ${drivePartlabelSecondary}";
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
            hashPathOld = config.sops.secrets."${config.aviary.secrets.luksHashPrevious}".path;
            hashPathNew = config.sops.secrets."${config.aviary.secrets.luksHash}".path; 
          in {

            ExecStart = "${execStart} ${hashPathOld} ${hashPathNew} ${drivePartlabelPrimary} ${drivePartlabelSecondary}";
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
        username =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.secrets.username}".path);
        description =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.secrets.description}".path);
        passwordHash =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.secrets.passwordHash}".path);
        adminSSHPub =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.aviary.secrets.sshAdminPub}".path);
    
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
