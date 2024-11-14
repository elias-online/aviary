{ config, inputs, lib, pkgs, ... }:
let
  secretsElias = builtins.toString inputs.secrets-elias;
in {

  config = {

    sops = {
      defaultSopsFile = "${secretsElias}/secrets/elias.yaml";
      secrets = {
        password-hash.neededForUsers = true;
	tailscale-authkey = {};
      };
    };

    services.displayManager.autoLogin = {
      enable = true;
      user = "elias";
    };

    users.users."elias" = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.password-hash.path;
      description = "Elias";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELnLG7uX0hFQ35gKBQG+YwSfXFnsHxcmtSNOxMiFEjl elias@ibis"
      ];
    };
  };
}
