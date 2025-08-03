{
  ...
}:

{
  config = {
    
    system.autoUpgrade = {
      enable = false;
      dates = "02:00";
      randomizedDelaySec = "45min";
      operation = "switch";
      flake = "github:elias-online/aviary";
      flags = ["-L"];
    };

    nix.gc = {
      automatic = true;
      options = "--delete-generations 14d";
      dates = "02:00";
      randomizedDelaySec = "45min";
    };

    services.fwupd.enable = true;
  };
}
