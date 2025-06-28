{
  config,
  lib,
  pkgs,
  ...
}: let
  mapper =
    if builtins.pathExists /tmp/egg-drive-name
    then (builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name))
    else config.networking.hostName;
  cryptsetupGeneratorService =
    "systemd-cryptsetup@disk\\x2dprimary\\x2dluks\\x2dbtrfs\\x2d" + mapper;
in {
  options.vpninitrd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "enable vpn in initrd";
    };

    tsKey = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ts-initrd";
      example = "hostname-ts-initrd";
      description = "tailscale initrd key secret name in sops-nix";
    };
  };

  config = lib.mkIf config.vpninitrd.enable {
    sops.secrets."${config.vpninitrd.tsKey}" = {};

    boot.initrd.systemd.tmpfiles.settings = {

      # Copy the tailscale key into initrd. This has the unfortunate side effect of exposing
      # the key to all users on the system via nix store which is why we use a different
      # tailscale key from the main system.
      "20-ts"."/run/secretsInitrd/ts-initrd".f = let
        content =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."${config.vpninitrd.tsKey}".path);
      in {
        group = "root";
        mode = "0400";
        user = "root";
        argument = content;
      };
      
      # Put the dbus socket where tailscaled expects to stop repetative error
      "50-tailescale"."/var/run".d = {
        argument = "/run";
        type = "L";
      };
    };

    boot.initrd.availableKernelModules = ["tun"];

    boot.initrd.systemd = {
      
      packages = with pkgs; [tailscale];
      initrdBin = with pkgs; [tailscale];
 
      services = {

        ${cryptsetupGeneratorService}.wants = ["network-online.target"];
        
        dbus.unitConfig.DefaultDependencies = "no";

        tailscaled = {
          wants = ["dbus.service" "network-online.target"];
          wantedBy = ["cryptsetup.target"];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Environment = [
            "PORT=${builtins.toString config.services.tailscale.port}"
            ''"FLAGS=--tun ${config.services.tailscale.interfaceName}"''
          ];
          preStart = "cat /run/secretsInitrd/ts-initrd";
          postStart = ''
            authKey="$(cat /run/secretsInitrd/ts-initrd)"
            tailscale up -authkey "$authKey"
          '';
          preStop = ''
            tailscale logout
          '';
        };
      };

      sockets.dbus.unitConfig.DefaultDependencies = "no";
    };

    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false; # Sometimes this fires after initrd
    
    # Disabling these might be a bad idea
    # These are tricky to get working in initrd and throw a [Depend] during boot
    systemd.services.systemd-networkd-persistent-storage.enable = false; # Persists mac address accross reboots
    systemd.services.network-local-commands.enable = false; # Hook for custom network commands
  };
}
