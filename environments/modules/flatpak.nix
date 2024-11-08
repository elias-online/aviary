{ config, lib, pkgs, ... }: {

  options.flatpak.enable = lib.mkEnableOption "enable flatpak and flathub";

  config = lib.mkIf config.flatpak.enable { 

    environment.systemPackages = with pkgs; [
      flatpak
      gnome.gnome-software
    ];

    systemd.user.services.flathub = {
      enable = true;
      after = [ "network-online.target" ];
      wantedBy = [ "default.target" ];
      description = "Add flathub repo if it isn't present";
      script = ''
        /run/current-system/sw/bin/flatpak -u remote-add --if-not-exists \
	    flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';

      serviceConfig = {
        Type = "oneshot";
	Restart = "on-failure";
	RestartSec = 30;
      };
    };

    services.flatpak.enable = true;
  };
}
