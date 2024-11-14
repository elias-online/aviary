{ config, inputs, ... }:
let
  secretsElias = builtins.toString inputs.secrets-elias;
in {

  config = {
    
    sops = {
      defaultSopsFile = "${secretsElias}/secrets/jason.yaml";
      secrets = {
        password-hash.neededForUsers = true;
	password-previous = {};
	password.restartUnits = [ "lukspwdsync.service" ];
	swallow-wg-env = {};
	crow-ssh-key = {
	  mode = "0600";
	  owner = "jason";
	  path = "/home/jason/.ssh/id_ed25519";
	};
	crow-ssh-key-public = {};
	tailscale-authkey = {};
      };
    };

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
