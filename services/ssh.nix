{...}: {
  config = {
    services.openssh = {
      enable = true;
      ports = [22];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        UseDns = true;
        PermitRootLogin = "prohibit-password";
      };

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [22];

    programs.ssh.askPassword = ""; #prevents gui for inputting ssh credentials
  };
}
