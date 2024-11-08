{ config, lib, ... }: {

  options.plymouth.enable = lib.mkEnableOption "enable plymouth";

  config = lib.mkIf config.plymouth.enable {

    boot = {
      kernelParams = [ "quiet" "splash" ];
      plymouth = {
        enable = true;
        theme = "spinner";
      };
    };
  };
}
