{
  config,
  lib,
  ...
}: {
  options.vpn = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "enable vpn";
    };

    tsKey = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName + "-ts";
      example = "hostname-ts";
      description = "tailscale key secret name in sops-nix";
    };
  };

  config = lib.mkIf config.vpn.enable {
    sops.secrets."${config.vpn.tsKey}" = {};

    services.tailscale.enable = true;

    systemd.services.tailscaled.postStart = ''
      authKey="$(cat /run/secrets/${config.vpn.tsKey})"
      /run/current-system/sw/bin/tailscale up -authkey "$authKey"
    '';

    environment.persistence."/persist".directories = [
      "/var/lib/tailscale"
    ];
  };
}
