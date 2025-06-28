{lib, ...}: {
  config = {
    networking.useNetworkd = lib.mkForce false;
    networking.wireless.enable = lib.mkForce false;

    boot.initrd.systemd.network.networks = {
      "99-ethernet-default-dhcp" = {
        matchConfig.Name = [ "en*" "eth*" ];

        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = "kernel";
        };
      };
      
      "99-wireless-client-dhcp" = {
        matchConfig.WLANInterfaceType = "station";

        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = "kernel";
        };

        dhcpV4Config.RouteMetric = 1025;
        ipv6AcceptRAConfig.RouteMetric = 1025;
      };
    };

    networking.networkmanager.enable = true;

    users.users = {
      "admin".extraGroups = ["networkmanager"];
      "1000".extraGroups = ["networkmanager"];
    };

    environment.persistence."/persist".directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
