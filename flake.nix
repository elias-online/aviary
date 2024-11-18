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
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    secrets-elias = {
      url = "git+ssh://git@github.com/elias-online/aviarySecretsElias.git?shallow=1";
      flake = false;
    };

    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {

      egg = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
	modules = [
	  inputs.impermanence.nixosModules.impermanence
	  inputs.sops-nix.nixosModules.sops

	  ./systems/egg.nix
	  ./environments/modules/default.nix
	  ./users/nixos.nix
	];
      };

      crow = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
	modules = [
	  inputs.disko.nixosModules.default
	  inputs.home-manager.nixosModules.default
	  inputs.impermanence.nixosModules.impermanence
	  inputs.sops-nix.nixosModules.sops

	  ./systems/crow.nix
	  ./users/jason.nix

	  ( import ./environments/default.nix {
	    environment = "desktop";
	  })

	];
      };

      ibis = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
	modules = [
	  inputs.disko.nixosModules.default
	  inputs.home-manager.nixosModules.default
	  inputs.impermanence.nixosModules.impermanence
	  inputs.sops-nix.nixosModules.sops

	  ./systems/ibis.nix
	  ./users/elias.nix

	  (import ./environments/default.nix {
	    environment = "desktop";
	  })
	];
      };

      pigeon = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
	modules = [
	  inputs.disko.nixosModules.default
	  inputs.home-manager.nixosModules.default
	  inputs.impermanence.nixosModules.impermanence
	  inputs.sops-nix.nixosModules.sops

	  ./systems/pigeon.nix
	  ./users/elias.nix

	  ( import ./environments/default.nix {
	    environment = "minimal";
	  })
	];
      };

      quail = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
	modules = [
	  inputs.disko.nixosModules.default
	  inputs.home-manager.nixosModules.default
	  inputs.impermanence.nixosModules.impermanence
	  inputs.sops-nix.nixosModules.sops

	  ./systems/quail.nix
	  ./users/galina.nix

	  (import ./environments/default.nix {
	    environment = "desktop";
	  })
	];
      };
    };
  };
}
