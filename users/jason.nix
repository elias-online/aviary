{ config, inputs, ... }:
let
  secretsElias = builtins.toString inputs.secrets-elias;
in {

  config = {
    
    sops = {
      defaultSopsFile = "${secretsElias}/secrets/jason.yaml";
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
    };
  };
}
