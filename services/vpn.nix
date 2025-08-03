{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit ( builtins )
    readFile
  ;

  inherit ( lib )
    mkForce
    mkIf
    mkOption
  ;

  inherit ( lib.types )
    bool
    str
  ;

  host = config.networking.hostName;
  
in {
  
  options.aviary = {
    
    vpn = mkOption {
      type = bool;
      default = true;
      example = false;
      description = "Enable VPN";
    };

    secrets = {

      ts = mkOption {
        type = str;
        default = host + "-ts";
        example = "hostname-ts";
        description = "SOPS-Nix secret storing tailscale key";
      };

      tsInitrd = mkOption {
        type = str;
        default = host + "-ts-initrd";
        example = "hostname-ts-initrd";
        description = "SOPS-Nix secret storing tailscale initrd key";
      };
    };
  };

  config = 

  let
    
    secrets = config.sops.secrets;
    secretsName = config.aviary.secrets;

    defaultPermissions = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };

  in mkIf config.aviary.vpn {

    sops.secrets = {
      
      "${secretsName.tsInitrd}" = defaultPermissions;
      "${secretsName.ts}" = defaultPermissions;

    };

    boot.initrd = {

      availableKernelModules = [ "tun" ];

      systemd = {

        tmpfiles.settings = {

          # Copy the ts key into initrd. This has the unfortunate side effect of exposing
          # the key to all users on the system via nix store which is why we use a different
          # tailscale key from the main system.
          "20-ts"."/run/secretsInitrd/ts-initrd".f = {
            group = "root";
            mode = "0400";
            user = "root";
            argument = readFile secrets."${secretsName.tsInitrd}".path;
          };

          # TODO try boot.initrd.systemd.dbus.enable instead
          # Put the dbus socket where tailscaled expects to stop repetative error
          "50-tailescale"."/var/run".d = {
            argument = "/run";
            type = "L";
          };
        };

        packages = [ pkgs.tailscale ];
        initrdBin = [ pkgs.tailscale ];

        # TODO try boot.initrd.systemd.dbus.enable instead
        sockets.dbus.unitConfig.DefaultDependencies = "no";

        services = {
        
          # TODO try boot.initrd.systemd.dbus.enable instead
          dbus.unitConfig.DefaultDependencies = "no";

          tailscaled = {
            wants = [ "dbus.service" "network-online.target" ];
            wantedBy = [ "cryptsetup.target" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig = {
              TimeoutSec = "infinity";
              Environment = [
                "PORT=${toString config.services.tailscale.port}"
                "FLAGS=\"--tun ${config.services.tailscale.interfaceName}\""
              ];
            };
            postStart = ''
              authKey="$(cat /run/secretsInitrd/ts-initrd)"
              tailscale up -authkey "$authKey"
            '';
            preStop = "tailscale logout";
          };
        };
      }; 
    };

    systemd.services.systemd-networkd-wait-online.enable = mkForce false; # Sometimes this fires after initrd
    
    # Disabling these might be a bad idea
    # These are tricky to get working in initrd and throw a [Depend] during boot
    systemd.services.systemd-networkd-persistent-storage.enable = false; # Persists mac address accross reboots
    systemd.services.network-local-commands.enable = false; # Hook for custom network commands

    services.tailscale.enable = true;

    systemd.services.tailscaled = {
      after = [ "systemd-networkd.service" ];
      #wants = [ "systemd-networkd.service" ];
      postStart = ''
        authKey="$(cat /run/secrets/${secretsName.ts})"
        /run/current-system/sw/bin/tailscale up -authkey "$authKey"
      '';
    };

    environment.persistence."/persist".directories = [
      "/var/lib/tailscale"
    ];
  };
}
