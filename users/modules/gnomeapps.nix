{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = {
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
