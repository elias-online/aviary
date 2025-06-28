{
  config,
  inputs,
  pkgs,
  ...
}: let
  secrets = builtins.toString inputs.secrets;
  defaultPerms = {
    mode = "0440";
    owner = config.users.users."1000".name;
    group = "admin";
  };
in {
  config = {
    sops = {
      defaultSopsFile = "${secrets}/00.yaml";
      secrets = {
        "email-git" = defaultPerms;
        "username-git" = defaultPerms;
        "ibis-ssh-user-pub" = defaultPerms;

        # Below this are managed secrets
	      "chicken-drive-primary" = defaultPerms;
        "chicken-luks-hash" = defaultPerms;
        "chicken-ssh-admin" = defaultPerms;
        "chicken-ssh-admin-pub" = defaultPerms;
        "chicken-ssh-host" = defaultPerms;
        "chicken-ssh-host-initrd" = defaultPerms;
	      "chicken-ssh-user" = {
	        mode = "0400";
	        owner = config.users.users."1000".name;
	        group = "admin";
	      };
        "chicken-ssh-user-pub" = defaultPerms;
        "chicken-ts" = defaultPerms;
        "chicken-ts-initrd" = defaultPerms;

        "egg-luks-hash" = defaultPerms;
        "egg-ssh-admin" = defaultPerms;
        "egg-ssh-admin-pub" = defaultPerms;
        "egg-ssh-host" = defaultPerms;
        "egg-ssh-host-initrd" = defaultPerms;
        "egg-ssh-user" = defaultPerms;
        "egg-ssh-user-pub" = defaultPerms;
        "egg-ts" = defaultPerms;
        "egg-ts-initrd" = defaultPerms; 

        "test-a-username" = defaultPerms;
        "test-a-description" = defaultPerms;
        "test-a-password-hash" = defaultPerms;
        "test-a-password-hash-previous" = defaultPerms;
        "test-a-luks-hash" = defaultPerms;
        "test-a-ssh-admin" = defaultPerms;
        "test-a-ssh-admin-pub" = defaultPerms;
        "test-a-ssh-host" = defaultPerms;
        "test-a-ssh-host-initrd" = defaultPerms;
        "test-a-ssh-user" = defaultPerms;
        "test-a-ssh-user-pub" = defaultPerms;
        "test-a-ts" = defaultPerms;
        "test-a-ts-initrd" = defaultPerms;
      };
    };

    users.users."1000" = let
      u00-ibis =
        builtins.replaceStrings ["\n"] [""]
        (builtins.readFile config.sops.secrets.ibis-ssh-user-pub.path);
    in {
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [u00-ibis];
    };

    home-manager = {
      users."1000" = {
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

        programs.git = let
          username =
            builtins.replaceStrings ["\n"] [""]
            (builtins.readFile config.sops.secrets."username-git".path);
          email =
            builtins.replaceStrings ["\n"] [""]
            (builtins.readFile config.sops.secrets."email-git".path);
        in {
          enable = true;
          userName = username;
          userEmail = email;
        };

        home.packages = with pkgs;
          lib.mkIf config.default.graphical [
            davinci-resolve-studio
            gnome-tweaks
            neovim-gtk
          ];
      };
    };
  };
}
