{ lib, ... }: {

  config = {

    boot = {
      loader.systemd-boot = lib.mkForce false;

      lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
    };

    environment.persistence."/persist".directories = [
      "/var/lib/sbctl"
      "/var/lib/stbctl/keys"
    ];
  };
}
