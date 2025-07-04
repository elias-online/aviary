{
  config,
  lib,
  ...
}: {
  options.bootstrap = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "enable bootstrap";
    };
  };

  config = lib.mkIf config.bootstrap.enable {
    boot = {
      loader = {
        timeout = 5;
        systemd-boot = {
          enable = true;
          configurationLimit = 15;
          consoleMode = "max";
          editor = false;
        }; 

        efi.canTouchEfiVariables = true;
      };

      initrd.systemd.enable = true;
    };

    systemd.enableEmergencyMode = false;
  };
}
