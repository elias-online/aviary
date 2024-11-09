{ config, lib, ... }: {

  options.print.enable = lib.mkEnableOption "enable print";

  config = lib.mkIf config.print.enable {

    services.printing.enable = true;
  };
}
