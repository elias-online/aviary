{ config, lib, inputs, ... }:
let
  secrets = builtins.toString inputs.secrets;
in {

  config = {

    sops.defaultSopsFile = "${secrets}/secrets/nixos.yaml";

    users.users.nixos = lib.mkForce {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "video" ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELnLG7uX0hFQ35gKBQG+YwSfXFnsHxcmtSNOxMiFEjl elias@ibis"
      ];
    };
  };
}
