# All credit for cryptsetup pcr15 check goes to patrick
# https://forge.lel.lol/patrick/nix-config/src/branch/master/modules/ensure-pcr.nix
# To enroll LUKS key:
# systemd-cryptenroll /dev/disk/by-partlabel/disk-main-luks --tpm2-device=auto --tpm2-pcrs=0+2+4+7

{
  config,
  inputs,
  lib,
  pkgs,
  utils,
  ...
}: {

  options.aviary = { 
    
    graphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Graphical environment flag";
    };

    # Verifies the identity of LUKS before decryption via PCR 15
    pcr15 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The expected value of PCR 15 after all luks partitions have been unlocked
        Should be a 64 character hex string as ouput by the sha256 field of
        'systemd-analyze pcrs 15 --json=short'
        If set to null (the default) it will not check the value.
        If the check fails the boot will abort and you will be dropped into an emergency shell, if enabled.
        In ermergency shell type:
        'systemctl disable check-pcrs'
        'systemctl default'
        to continue booting
      '';
      example = "6214de8c3d861c4b451acc8c4e24294c95d55bcec516bbf15c077ca3bffb6547";
    };

    boot.initrd.luks.devices = lib.mkOption {
      type =
        with lib.types;
        attrsOf (submodule {
          config.crypttabExtraOpts = [
            "tpm2-device=auto"
            "tpm2-measure-pcr=yes"
          ];
        });
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

    boot.kernelParams = [ "rd.luks=no" ];

    boot.initrd.systemd = 

    let
      cryptExecStart = (pkgs.writeShellScript "cryptsetup" ''${ builtins.readFile ../../scripts/systemd/cryptsetup.sh }'');
      cryptExecStartPost = (pkgs.writeShellScript "impermanence" ''${ builtins.readFile ../../scripts/systemd/impermanence.sh }'');
      deviceDisk = "disk-primary-luks-${mapper}";
      deviceMapper = "disk-primary-luks-btrfs-${mapper}";

      saltPassword = builtins.head (
        builtins.match "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" (
          builtins.replaceStrings ["\n"] [""] (
            builtins.readFile config.sops.secrets."${config.aviary.secrets.passwordHash}".path
          )
        )
      );
  
      saltRecovery = builtins.head (
        builtins.match  "^(\\$y\\$[^$]+\\$[^$]+)\\$[^$]+$" (
          builtins.replaceStrings ["\n"] [""] (
            builtins.readFile config.sops.secrets."${config.aviary.secrets.luksHash}".path
          )
        )
      );
    in {

      packages = with pkgs; [mkpasswd];
      initrdBin = with pkgs; [mkpasswd];

      services = {

        systemd-ask-password-console.wantedBy = ["cryptsetup.target"]; 

        check-pcrs = lib.mkIf (config.aviary.pcr15 != null) {
          script = ''
            echo "Checking PCR 15 value"
            if [[ $(systemd-analyze pcrs 15 --json=short | jq -r ".[0].sha256") != "${config.aviary.pcr15}" ]] ; then
              echo "PCR 15 check failed"
              exit 1
            else
              echo "PCR 15 check suceed"
            fi
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          unitConfig.DefaultDependencies = "no";
          after = [ "cryptsetup.target" ];
          before = [ "sysroot.mount" ];
          requiredBy = [ "sysroot.mount" ];
        };
      }
      // (lib.listToAttrs (
        lib.foldl' (
          acc: attrs:
          let
            extraOpts = attrs.value.crypttabExtraOpts ++ (lib.optional attrs.value.allowDiscards "discard");
            cfg = config.boot.initrd.systemd;
            flags = lib.concatStringsSep "," extraOpts;
          in
          [
            (lib.nameValuePair "cryptsetup-${attrs.name}" {
              unitConfig = {
                Description = "Cryptography setup for ${attrs.name}";
                DefaultDependencies = "no";
                IgnoreOnIsolate = true;
                Conflicts = [ "umount.target" ];
                BindsTo = "${utils.escapeSystemdPath attrs.value.device}.device";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                TimeoutSec = "infinity";
                KeyringMode = "shared";
                OOMScoreAdjust = 500;
                ImportCredential = "cryptsetup.*";
                ExecStart = "${cryptExecStart} ${cfg.package} ${attrs.name} ${attrs.value.device} ${flags} \$${saltPassword} \$${saltRecovery}";
                ExecStartPost =
                  if "${attrs.name}" == "${deviceMapper}"
                  then "${cryptExecStartPost} ${attrs.name}"
                  else "";
                ExecStop = ''${cfg.package}/bin/systemd-cryptsetup detach '${attrs.name}' '';
              };
              after = [
                "cryptsetup-pre.target"
                "systemd-udevd-kernel.socket"
                "wpa_supplicant-initrd.service"
                "${utils.escapeSystemdPath attrs.value.device}.device"
              ]
              ++ (lib.optional cfg.tpm2.enable "systemd-tpm2-setup-early.service")
              ++ lib.optional (acc != [ ]) "${(lib.head acc).name}.service";
              before = [
                "blockdev@dev-mapper-${attrs.name}.target"
                "cryptsetup.target"
                "umount.target"
              ];
              wants = [ "blockdev@dev-mapper-${attrs.name}.target" ];
              requiredBy = [ "sysroot.mount" ];
              requires = [ "wpa_supplicant-initrd.service" ];
            })
          ]
          ++ acc
        ) [ ] (lib.sortOn (x: x.name) (lib.attrsets.attrsToList config.boot.initrd.luks.devices))
      ));

      storePaths = [
        cryptExecStart
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
