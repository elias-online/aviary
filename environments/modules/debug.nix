{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    boot = {
      initrd.systemd = {
        #emergencyAccess = true; # allow unauthenticated initrd access
        packages = with pkgs; [
          coreutils
          curl
          gnugrep
          iproute2
          iputils
          traceroute
          wget
        ];
        initrdBin = with pkgs; [
          coreutils
          curl
          gnugrep
          iproute2
          iputils
          traceroute
          wget
        ];
      };

      kernelParams = [
        #"rd.systemd.unit=rescue.target" # force initrd into rescue mode
        "rd.systemd.debug_shell" # open initrd debug shell on tty9
      ];
    };

    # getty login is disabled for egg so make sure it's enabled
    services.getty = {
      loginProgram = lib.mkForce "${pkgs.shadow}/bin/login";
      loginOptions = lib.mkForce null;
      extraArgs = lib.mkForce [];
    };

    users.users.root.password = config.users.users.root.name;
    users.users."admin".password = config.users.users."admin".name;
    users.users."admin".hashedPassword = lib.mkForce null;
    users.users."1000".password = config.users.users."1000".name;
    users.users."1000".hashedPassword = lib.mkForce null;
  };
}
