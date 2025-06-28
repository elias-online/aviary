{ config, inputs, ... }:
let
  secrets = builtins.toString inputs.secrets;

  u00-ibis = builtins.replaceStrings ["\n"] [""]
             (builtins.readFile config.sops.secrets."ibis-ssh-user-pub".path);
in {

  config = {
    
    sops = {
      defaultSopsFile = "${secrets}/02.yaml";
      secrets."ibis-ssh-user-pub" = {};
    };

    users.users."admin".openssh.authorizedKeys.keys = [ u00-ibis ];
  };
}
