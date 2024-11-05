{ config, lib, pkgs, ... }: {

  options.package.enable = lib.mkEnableOption "enable package";

  config = lib.mkIf config.package.enable {

    environment.systemPackages = with pkgs; [
      home-manager
      linux-firmware
    ];
  };
}
