{ config, lib, ... }: {

  imports = [ 
    ./modules/default.nix
  ];

  options.desktop.enable = lib.mkEnableOption "enable desktop environment";

  config = lib.mkIf config.desktop.enable {

    bluetooth.enable = true;
    bootload.enable = true;
    flatpak.enable = true;
    gnome.enable = true;
    impermanence.enable = true;
    lukspwdsync.enable = true;
    network.enable = true;
    package.enable = true;
    pipewire.enable = true;
    plymouth.enable = true;
    powerprofile.enable = true;
    print.enable = true;
    secrets.enable = true;
    update.enable = true;
    vpn.enable = true;
  };
}
