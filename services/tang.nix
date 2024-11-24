{ ... }: {

  services.tang = {
    enable = true;
    ipAddressAllow = [ "192.168.1.122/32" ];
  };

  networking.firewall.allowedTCPPorts = [ 7654 ];
}
