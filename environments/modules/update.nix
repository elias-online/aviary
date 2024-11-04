{ config, inputs, lib, ... }: {

  options.update.enable = lib.mkEnableOption "enable update";

  config = lib.mkIf config.update.enable {

    system.autoUpgrade = {
      enable = true;
      dates = "02:00";
      randomizedDelaySec = "45min";
      operation = "switch";
      flake = "github:elias-online/aviary";
      flags = [ "-L" ];
    };

    nix.gc = {
      automatic = true;
      options = "--delete-generations 14d";
      dates = "02:00";
      randomizedDelaySec = "45min";
    };
  };
}
