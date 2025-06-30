{
  description = "NixOS Aviary Flake by Elias";

  inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/elias-online/aviarySecrets.git";
      flake = false;
    };

    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    #pkgs = nixpkgs.legacyPackages.${system};
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    formatter.${system} = pkgs.alejandra;

    nixosModules = {
      default = _: {
        imports = [
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.sops-nix.nixosModules.sops
          ./environments/modules/bootstrap.nix
          ./environments/modules/default.nix
          ./environments/modules/usersbase.nix
        ];
      };

      debug = _: {
        imports = [
          ./environments/modules/debug.nix
        ];
      };

      graphical = _: {
        imports = [
          self.nixosModules.minimal #default
          #self.nixosModules.remote
          ./environments/modules/bluetooth.nix
          ./environments/modules/flatpak.nix
          ./environments/modules/gnome.nix
          ./environments/modules/networkmanager.nix
          ./environments/modules/pipewire.nix
          ./environments/modules/plymouth.nix
          ./environments/modules/powerprofile.nix
          ./environments/modules/print.nix
          #./environments/modules/update.nix 
        ];
      };

      graphicalHyprland = _: {
        imports = [
	        self.nixosModules.minimal #default
          #self.nixosModules.remote
	        ./environments/modules/hyprland.nix
	        ./environments/modules/networkmanager.nix
	        ./environments/modules/plymouth.nix
          #./environments/modules/update.nix
	      ];
      };

      minimal = _: {
        imports = [
          self.nixosModules.default
          self.nixosModules.remote
          ./environments/modules/secureboot.nix
          ./environments/modules/update.nix
        ];
      };

      recovery = _: {
        imports = [
          self.nixosModules.default
          self.nixosModules.remote
          ./environments/modules/recovery.nix
          ./environments/modules/update.nix
        ];
      };

      remote = _: {
        imports = [
          ./services/ssh.nix
          ./services/sshinitrd.nix 
          ./services/vpn.nix
          ./services/vpninitrd.nix
        ];
      };
    };

    # Run with:
    # nix run -L .#checks.x86_64-linux.<test>.driver --impure
    # nix run -L .#checks.x86_64-linux.<test>.driverInteractive --impure
    checks.${system} = let
      makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
      eval-config = import (pkgs.path + "/nixos/lib/eval-config.nix");
      lib = pkgs.lib;
      diskoLib = import (inputs.disko + "/lib") {inherit lib makeTest eval-config;};
    in {
      "deploy" = pkgs.testers.runNixOSTest (
        import ./tests/deploy.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );

      "egg" = diskoLib.testLib.makeDiskoTest (
        import ./tests/egg.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );

      "gnome" = pkgs.testers.runNixOSTest (
        import ./tests/gnome.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );

      "hyprland" = pkgs.testers.runNixOSTest (
        import ./tests/hyprland.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );

      "impermanence" = diskoLib.testLib.makeDiskoTest (
        import ./tests/impermanence.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );

      "login" = diskoLib.testLib.makeDiskoTest (
        import ./tests/login.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );

      "syncluks" = diskoLib.testLib.makeDiskoTest (
        import ./tests/syncluks.nix {
          inherit inputs nixpkgs pkgs self;
        }
      );
    };

    nixosConfigurations = {
      
      "chicken" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
	      modules = [
	        self.nixosModules.graphical
	        ./systems/chicken.nix
	        ./users/00.nix
          self.nixosModules.debug # TODO REMOVE ME
	      ];
      };

      "deploy-test" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          self.nixosModules.recovery
          ./systems/egg.nix
          ./tests/users/headless.nix
        ];
      };

      "egg" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          self.nixosModules.recovery
          self.nixosModules.debug # TODO REMOVE ME
          ./systems/egg.nix
          ./users/recovery.nix
        ];
      };

      "ibis" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          self.nixosModules.graphical
          ./systems/ibis.nix
          ./users/00.nix
        ];
      };
    };
  };
}
