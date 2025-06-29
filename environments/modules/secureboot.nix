# To enroll secureboot keys:
# sbctl create-keys

{ lib, pkgs, ... }: {
  config = {
    
    environment.systemPackages = [ pkgs.sbctl ];

    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
    };
  };
}
