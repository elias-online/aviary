{ config, lib, ... }: {

  imports = [
    ./modules/default.nix
    ./modules/secrets.nix
  ];

  options.minimal.enable = lib.mkEnableOption "enable minimal environment";

  config = lib.mkIf config.minimal.enable {

    bootload.enable = true;
    impermanence.enable = true;
    lukspwdsync.enable = true;
    network.enable = true;
    package.enable = true;
    secrets.enable = true;
    update.enable = true;
    vpn.enable = true;
  };
}
