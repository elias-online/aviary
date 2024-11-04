{ config, lib, ... }: {

  options.bootload.enable = lib.mkEnableOption "enable bootload";

  config = lib.mkIf config.bootload.enable {

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
