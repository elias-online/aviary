{ config, lib, ... }: {

  options.bluetooth.enable = lib.mkEnableOption "enable bluethooth";
  
  config = lib.mkIf config.bluetooth.enable {

    hardware.bluetooth.enable = true;
  };
}
