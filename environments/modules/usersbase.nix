{
  config,
  inputs,
  lib,
  ...
}: let
  mapper =
    if builtins.pathExists /tmp/egg-drive-name
    then (builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name))
    else config.networking.hostName;
  primary = "disk-primary-luks-btrfs-" + mapper;
  secondary = "disk-secondary-luks-btrfs-" + mapper;
in {
  options.usersbase = {
    usernameSecret = lib.mkOption {
      type = lib.types.str;
      default = "username";
      example = "user-username";
      description = "username secret name in sops-nix";
    };

    descriptionSecret = lib.mkOption {
      type = lib.types.str;
      default = "description";
      example = "user-description";
      description = "description secret name in sops-nix";
    };

    passwordHashSecret = lib.mkOption {
      type = lib.types.str;
      default = "password-hash";
      example = "user-password-hash";
      description = "password-hash secret name in sops-nix";
    };

    passwordHashPreviousSecret = lib.mkOption {
      type = lib.types.str;
      default = "password-hash-previous";
      example = "user-password-hash-previous";
      description = "password-hash-previous secret name in sops-nix";
    };

    sshAdminSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-admin";
      example = "hostname-ssh-admin";
      description = "ssh admin key secret name in sops-nix";
    };

    sshAdminPubSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-admin-pub";
      example = "hostname-ssh-admin-pub";
      description = "ssh admin public key secret name in sops-nix";
    };

    sshUserSecret = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ssh-user";
      example = "hostname-ssh-user";
      description = "ssh user key secret name in sops-nix";
    };
  };

  config = {
    sops.secrets = {
      "${config.usersbase.usernameSecret}" = {
        mode = "0440";
        owner = config.users.users."1000".name;
        group = "admin";
      };
      "${config.usersbase.descriptionSecret}" = {
        mode = "0440";
        owner = config.users.users."1000".name;
        group = "admin";
      };
      "${config.usersbase.passwordHashSecret}" = {
        mode = "0440";
        owner = config.users.users."1000".name;
        group = "admin";
      };
      "${config.usersbase.passwordHashPreviousSecret}" = {
        restartUnits = ["syncluks.service"];
        mode = "0440";
        owner = config.users.users."1000".name;
        group = "admin";
      };
      "${config.usersbase.sshAdminSecret}" = lib.mkForce {
        mode = "0400";
        owner = config.users.users."admin".name;
        group = "admin";
        path = "/home/admin/.ssh/id_ed25519";
      };
      "${config.usersbase.sshAdminPubSecret}" = {
        mode = "0440";
        owner = config.users.users."1000".name;
        group = "admin";
      };
      "${config.usersbase.sshUserSecret}" = lib.mkForce {
        mode = "0400";
        owner = config.users.users."1000".name;
        group = "admin";
        path = "/home/1000/.ssh/id_ed25519";
      };
    };

    systemd.tmpfiles.rules = [
      "d /home/1000/.ssh 0700 ${config.users.users."1000".name} users -"
      "d /home/admin/.ssh 0700 admin admin -"
    ];

    users.groups.admin = {};

    users.users = let
      username =
        builtins.replaceStrings ["\n"] [""]
        (builtins.readFile config.sops.secrets."${config.usersbase.usernameSecret}".path);
      description =
        builtins.replaceStrings ["\n"] [""]
        (builtins.readFile config.sops.secrets."${config.usersbase.descriptionSecret}".path);
      passwordHash =
        builtins.replaceStrings ["\n"] [""]
        (builtins.readFile config.sops.secrets."${config.usersbase.passwordHashSecret}".path);
      adminSSHPub =
        builtins.replaceStrings ["\n"] [""]
        (builtins.readFile config.sops.secrets."${config.usersbase.sshAdminPubSecret}".path);
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

    security.sudo.extraRules = [
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

    systemd.services."syncluks" = {
      enable = true;
      description = "Syncronize luks passkey with user password";
      serviceConfig = {
        StandardOutput = "null";
        StandardError = "null";
      };

      script = ''
        oldKey=$(head -n1 ${config.sops.secrets."${config.usersbase.passwordHashPreviousSecret}".path})
        newKey=$(head -n1 ${config.sops.secrets."${config.usersbase.passwordHashSecret}".path})
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
