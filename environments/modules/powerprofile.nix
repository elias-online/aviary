{ config, lib, ... }: {

  options.powerprofile.enable = lib.mkEnableOption "enable powerprofile";

  config = lib.mkIf config.powerprofile.enable {
 
    services.power-profiles-daemon.enable = true;
  };
}
