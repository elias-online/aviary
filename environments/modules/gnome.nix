{
  config,
  lib,
  pkgs,
  ...
}: {
  options.gnome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "enable gnome desktop environment";
    };
  };

  config = lib.mkIf config.gnome.enable {
    default.graphical = true;

    environment.gnome.excludePackages = with pkgs; [
      #removes default extensions
      gnome-shell-extensions
    ];

    services = {
      xserver = {
        enable = true;
        excludePackages = [pkgs.xterm];
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };

      gnome.core-utilities.enable = false; #removes default apps
    };

    #GDM autologin config--may crash if the first two lines aren't present
    #https://github.com/NixOS/nixpkgs/issues/103746#issuecomment=945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    services.displayManager.autoLogin = {
      enable = true;
      user = config.users.users."1000".name;
    };

    environment = {
      systemPackages = with pkgs; [
        ghostty
        gnome-disk-utility
        gnome-logs
        gnome-themes-extra
        nautilus
        nautilus-python
        yelp
        libgtop
        mission-center
      ];

      #enable nautilus extensions
      pathsToLink = ["/share/nautilus-python/extensions"];
      sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";

      variables.GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0"; #for tophat ext
    };

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };
  };
}
