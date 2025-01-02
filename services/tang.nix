{ ... }: {

  services.tang = {
    enable = true;
    ipAddressAllow = [ "192.168.8.0/24" ];
    listenStream = [ "7654" ];
  };

  networking.firewall.allowedTCPPorts = [ 7654 ];

}
