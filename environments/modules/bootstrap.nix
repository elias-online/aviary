{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkForce
    mkIf
    mkOption
    ;

  inherit (lib.types)
    bool
    ;

in {

  options.bootstrap = {
    
    enable = mkOption {
      type = bool;
      default = true;
      example = false;
      description = "enable bootstrap";
    };
  };

  config = mkIf config.bootstrap.enable {
    
    boot = { 
      loader = {
        timeout = 5;
        systemd-boot = {
          enable = mkForce false; # Using Lanzaboote
          consoleMode = "max";
          editor = false;
        }; 

        efi.canTouchEfiVariables = true;
      };

      lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      initrd.systemd.enable = true;
    };

    systemd.enableEmergencyMode = false;

    environment.persistence."/persist".directories = [
      "/var/lib/sbctl"
    ];
  };
}
