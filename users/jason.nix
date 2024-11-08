{ config, inputs, ... }:
let
  secretsElias = builtins.toString inputs.secrets-elias;
in {

  config = {
    
    sops = {
      defaultSopsFile = "${secretsElias}/secrets/jason.yaml";
      secrets = {
        password-hash.neededForUsers = true;
      };
    };

    users.users."jason" = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.password-hash.path;
      description = "Jason";
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };
}
