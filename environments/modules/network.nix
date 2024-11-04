{ config, lib, ... }: {

  options.network.enable = lib.mkEnableOption "enable network";

  config = lib.mkIf config.network.enable {

    networking.networkmanager.enable = true;
    
    programs.ssh.askPassword = ""; #prevents gui for inputting ssh credentials
    
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        UseDns = true;
        PermitRootLogin = "no";
      };
      hostKeys = [{
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
    };

    networking.firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [  ];
      checkReversePath = false;
    };
  };
}
