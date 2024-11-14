{ config, lib, ... }: {

  options.vpn.enable = lib.mkEnableOption "enable vpn";

  config = lib.mkIf config.vpn.enable {

    networking.networkmanager.ensureProfiles = {

      environmentFiles = [ config.sops.secrets."swallow-wg-env".path ];

      profiles.swallow = {
        connection = {
          id = "Swallow";
          interface-name = "wg0";
          type = "wireguard";
	  autoconnect = "false";
          permissions = "$SWALLOW_PERMISSIONS";
        };

        "wireguard-peer.$SWALLOW_PUBLIC_KEY" = {
          endpoint = "$SWALLOW_ENDPOINT";
          persistent-keepalive = "25";
          allowed-ips = "0.0.0.0/0;::/0;";
        };

        ipv4 = {
          dns = "$SWALLOW_DNS";
          method = "manual";
        };

        ipv6 = {
          addr-gen-mode = "stable-privacy";
          method = "ignore";
	};
      };
    };

    services.tailscale.enable = true;
  };
}
