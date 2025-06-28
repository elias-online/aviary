{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = {
    fonts.fontconfig.enable = true;

    home.packages = [(pkgs.nerdfonts.override {fonts = ["SourceCodePro"];})];

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        enable-hot-corners = false;
        show-battery-percentage = true;
        clock-show-weekday = true;
        clock-show-seconds = true;
        color-scheme = "prefer-dark";
        monospace-font-name = "SauceCodePro Nerd Font 10";
        gtk-theme = "Adwaita-dark";
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = true;
        edge-tiling = true;
        center-new-windows = true;
      };

      "org/gnome/desktop/privacy" = {
        remove-old-temp-files = true;
        remove-old-trash-files = true;
        recent-files-max-age = 30;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
      };

      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat";
      };

      "org/gnome/desktop/calendar" = {
        show-weekdate = true;
      };

      "org/gnome/desktop/search-providers" = {
        sort-order = [
          "org.gnome.Documents.desktop"
          "org.gnome.Calculator.desktop"
          "org.gnome.Nautilus.desktop"
          "org.gnome.Contacts.desktop"
          "org.gnome.seahorse.Application.desktop"
          "org.gnome.Settings.desktop"
          "org.gnome.clocks.desktop"
          "org.gnome.Weather.desktop"
          "org.gnome.Software.desktop"
          "org.gnome.Characters.desktop"
        ];
        disabled = [];
      };

      "org/gnome/settings-daemon/plugins/power" = {
        ambient-enabled = false;
      };

      # DEFAULT GNOME APPS
      "com/raggesilver/BlackBox" = {
        remember-window-size = true;
        font = "SauceCodePro Nerd Font 12";
        terminal-padding = lib.hm.gvariant.mkTuple [
          (lib.hm.gvariant.mkUint32 5)
          (lib.hm.gvariant.mkUint32 5)
          (lib.hm.gvariant.mkUint32 5)
          (lib.hm.gvariant.mkUint32 5)
        ];
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = true;
      };

      "osrg/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
      };

      "org/gnome/nautilus/list-view" = {
        default-visible-columns = [
          "name"
          "size"
          "owner"
          "permissions"
          "date_modified"
        ];
      };
    };
  };
}
