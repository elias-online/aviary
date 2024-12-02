{ config, inputs, lib, pkgs, ... }: {

  options.gnomeapps.enable = lib.mkEnableOption "enable gnome apps";

  config = lib.mkIf config.gnomeapps.enable {

    home.packages = with pkgs; [
      amberol
      clapper
      evince
      gnome-text-editor
      gnome-calculator
      gnome-calendar
      gnome-clocks
      gnome-contacts
      gnome-tweaks
      gnome-weather
      loupe
      snapshot
    ];
  };
}
