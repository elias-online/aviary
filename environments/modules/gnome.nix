{ config, lib, pkgs, ... }: {

  options.gnome.enable = lib.mkEnableOption "enable gnome";

  config = lib.mkIf config.gnome.enable {

    environment.gnome.excludePackages = with pkgs; [ #removes default extensions
      gnome.gnome-shell-extensions
    ];

    services = {
      xserver = {
        enable = true;
        excludePackages = [ pkgs.xterm ];
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    
      gnome.core-utilities.enable = false; #removes default apps
    };
    
    #GDM autologin config--may crash if the first two lines aren't present
    #https://github.com/NixOS/nixpkgs/issues/103746#issuecomment=945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    environment = {
     systemPackages = with pkgs; [
	blackbox-terminal
        gnome.gnome-disk-utility
        gnome.gnome-logs
	gnome.gnome-themes-extra
        gnome.nautilus
        gnome.nautilus-python
        gnome.yelp
        libgtop
        mission-center
      ];

      #enable nautilus extensions
      pathsToLink = [ "/share/nautilus-python/extensions" ];
      sessionVariables.NAUTILUS_4_EXTENSION_DIR =
        "${pkgs.gnome.nautilus-python}/lib/nautilus/extensions-4";

      variables.GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0"; #for tophat ext
    };

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "blackbox";
    };
  };
}