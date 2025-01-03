{ config, inputs, ... }:
let
  secrets = builtins.toString inputs.secrets;
in {

  config = {
    
    sops = {
      defaultSopsFile = "${secrets}/secrets/jason.yaml";
      secrets = {
        password-hash.neededForUsers = true;
	crow-ssh-key = if builtins.toString config.networking.hostName == "crow" then {
	  mode = "0600";
	  owner = "jason";
	  path = "/home/jason/.ssh/id_ed25519";
	} else {};
      };
    };

    systemd.tmpfiles.rules = [
      "d /home/jason/.ssh 0700 jason users -"
    ];

    services.displayManager.autoLogin = {
      enable = true;
      user = "jason";
    };

    users.users."jason" = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.password-hash.path;
      description = "Jason";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELnLG7uX0hFQ35gKBQG+YwSfXFnsHxcmtSNOxMiFEjl elias@ibis"
      ];
    };
  };
}
