{ config, pkgs, ... }: {

  config = {

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # Nudge electron apps to use wayland
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Automatically login
    services.getty.autologinUser = config.users.users."1000".name;
    
    # Automatically login to TTY1 only
    #systemd.services."getty@tty1" = {
    #  overrideStrategy = "asDropin";
    #  serviceConfig.ExecStart = ["" "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${config.users.users."1000".name} --noclear --keep-baud %I 115200,38400,9600 $TERM"];
    #};

    home-manager.users."1000" = {
      
      home.packages = with pkgs; [
        kitty
	nautilus
	gnome-calculator
      ];

      programs = {
        kitty.enable = true;
        
	# Autostart Hyprland with UWSM after login on tty1
	bash = {
	  enable = true;
	  profileExtra = ''
            if uwsm check may-start; then
                exec uwsm start hyprland-uwsm.desktop
            fi
          '';
	};
      };

      wayland.windowManager.hyprland = {
        
	enable = true;
        systemd.enable = false;

	plugins = with pkgs; [
	  #hyprlandPlugins.hyprbars
	];
	
	settings = {
          
	  "$mod" = "CTRL_SHIFT";
	  
	  bind = [
	    "$mod, Q, killactive,"
	    "$mod, 1, exec, kitty"
	    "$mod, 2, exec, nautilus"
	    "$mod, 3, exec, gnome-calculator"
	  ];

	  plugin = {
	    /*
	    hyprbars = {
	      "bar_height" = "20";

	      "hyprbars-button" = [
	        "rgb(ff4040), 10, 󰖭, hyprctl dispatch killactive"
                "rgb(eeee11), 10, , hyprctl dispatch fullscreen 1"
	      ];
	    };
	    */
	  };
        };
      };
    };
  };
}
