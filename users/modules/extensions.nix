{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  config = {
    home.packages = with pkgs; [
      gnomeExtensions.gsconnect
      gnomeExtensions.launch-new-instance
      gnomeExtensions.paperwm
      gnomeExtensions.tophat
    ];

    dconf.settings = {
      "org/gnome/shell/extensions/tophat" = {
        network-usage-unit = "bits";
      };

      "org/gnome/shell/extensions/paperwm" = {
        show-window-position-bar = false;
        selection-border-size = 0;
        window-gap = 10;
        horizontal-margin = 10;
        vertical-margin = 10;
        vertical-margin-bottom = 10;
        use-default-background = true;
        show-workspace-indicator = false;
        disable-topbar-styling = true;
        minimap-scale = 0.0;
        maximize-width-percent = 1.0;
        show-focus-mode-icon = false;
        cycle-width-steps = [
          0.33332999999999996
          0.5
          0.66666999999999998
          1.0
        ];
        cycle-height-steps = [
          0.33332999999999996
          0.5
        ];
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:maximize,close";
        action-right-click-titlebar = "none";
      };

      "org/gnome/shell".enabled-extensions = [
        "gsconnect@andyholmes.github.io"
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "paperwm@paperwm.github.com"
        "tophat@fflewddur.github.io"
      ];
    };
  };
}
