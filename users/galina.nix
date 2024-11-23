{ config, inputs, ... }:
let
  secrets = builtins.toString inputs.secrets;
in {

  config = {

    sops = {
      defaultSopsFile = "${secrets}/secrets/galina.yaml";
      secrets = {
        password-hash.neededForUsers = true;
	quail-ssh-key = if builtins.toString config.networking.hostName == "quail" then {
	  mode = "0600";
	  owner = "galina";
	  path = "/home/galina/.ssh/id_ed25519";
	} else {};
      };
    };

    systemd.tmpfiles.rules = [
      "d /home/galina/.ssh 0700 galina users -"
    ];

    services.displayManager.autoLogin = {
      enable = true;
      user = "galina";
    };

    users.users."galina" = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.password-hash.path;
      description = "Galina";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELnLG7uX0hFQ35gKBQG+YwSfXFnsHxcmtSNOxMiFEjl elias@ibis"
      ];
    };
  };
}
