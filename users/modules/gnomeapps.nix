{ config, inputs, lib, pkgs, ... }: {

  options.gnomeapps.enable = lib.mkEnableOption "enable gnome apps";

  config = lib.mkIf config.gnomeapps.enable {

    home.packages = with pkgs; [
      amberol
      clapper
      evince
      gnome-text-editor
      gnome.gnome-calculator
      gnome.gnome-calendar
      gnome.gnome-clocks
      gnome.gnome-contacts
      gnome.gnome-tweaks
      gnome.gnome-weather
      loupe
      snapshot
    ];
  };
}
