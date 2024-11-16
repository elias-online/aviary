{ config, inputs, lib, pkgs, ... }:
let
  secretsElias = builtins.toString inputs.secrets-elias;
in {

  config = {

    sops = {
      defaultSopsFile = "${secretsElias}/secrets/elias.yaml";
      secrets = {
        password-hash.neededForUsers = true;
	password.restartUnits = [ "lukspwdsync.service" ];
	password-previous = {};
	ibis-ssh-key = if builtins.toString config.networking.hostName == "ibis" then {
	  mode = "0600";
	  owner = "elias";
	  path = "/home/elias/.ssh/id_ed25519";
	} else {};
      };
    };

    systemd.tmpfiles.rules = [
      "d /home/elias/.ssh 0700 elias users -"
    ];

    services.displayManager.autoLogin = {
      enable = true;
      user = "elias";
    };

    users.users."elias" = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.password-hash.path;
      description = "Elias";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELnLG7uX0hFQ35gKBQG+YwSfXFnsHxcmtSNOxMiFEjl elias@ibis"
      ];
    };

    home-manager = {
      extraSpecialArgs = { inherit inputs; };

      users.elias = {
        
	imports = [
	  inputs.nixvim.homeManagerModules.nixvim

	  ./modules/extensions.nix
	  ./modules/gnomeapps.nix
	  ./modules/keybinds.nix
	  ./modules/librewolf.nix
	  ./modules/neovim.nix
	  ./modules/shell.nix
	  ./modules/starship.nix
	];

	extensions.enable = lib.mkIf config.desktop.enable true;
	gnomeapps.enable = lib.mkIf config.desktop.enable true;
	keybinds.enable = lib.mkIf config.desktop.enable true;
	librewolf.enable = lib.mkIf config.desktop.enable true;
	shell.enable = lib.mkIf config.desktop.enable true;
	starship.enable = lib.mkIf config.desktop.enable true;

	home = {
	  stateVersion = "24.05";
	  username = "elias";
	  homeDirectory = "/home/elias";
	};

	programs = {
	  git = {
	    enable = true;
	    userName = "elias-online";
	    userEmail = "ichash@proton.me";
	  };
	  home-manager.enable = true;
	};

	home.packages = with pkgs; lib.mkIf config.desktop.enable [
	  davinci-resolve-studio
	  gnome.gnome-tweaks
	  librewolf
	  neovim-gtk
	];
      };
    };
  };
}
