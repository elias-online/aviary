{
  config,
  inputs,
  lib,
  ...
}: let
  secrets = builtins.toString inputs.secrets;

  u00-ibis = builtins.replaceStrings ["\n"] [""]
             (builtins.readFile config.sops.secrets."ibis-ssh-user-pub".path);
in {

  config = {

    sops = {
      defaultSopsFile = "${secrets}/recovery.yaml";
      secrets."ibis-ssh-user-pub" = {};
    };

    users.users = {

      root.openssh.authorizedKeys.keys = [u00-ibis];
      
      "admin".openssh.authorizedKeys.keys = [u00-ibis];

      "1000" = {
        extraGroups = [ "wheel" ];
        hashedPasswordFile = lib.mkForce null;
        openssh.authorizedKeys.keys = [u00-ibis];
      };
    };
  };
}
