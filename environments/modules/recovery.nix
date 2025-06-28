{
  config,
  lib,
  pkgs,
  ...
}: {
  config = { 

    systemd.targets.multi-user.wants = [ "wpa_supplicant-recovery.service" ];

    systemd.services = {
      "wpa_supplicant-recovery" = {
        description = "WPA supplicant daemon (for interface wifi0)";
        requires = [ "sys-subsystem-net-devices-wifi0.device" ];
        after = [ "sys-subsystem-net-devices-wifi0.device" ];
        before = [ "network.target" ];
        wants = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "simple";
        script = ''
          /run/current-system/sw/bin/wpa_supplicant -c /persist/wpa_supplicant-wifi0.conf -i wifi0
        '';
      };

      tailscaled.preStop = ''
        tailscale logout # TODO Doesn't work at shutdown or manual stop
      '';
    };

    security.sudo.wheelNeedsPassword = false;
    security.polkit.enable = true; # reboot without password

    # recovery devices should not be updated as they are ephemeral and impure
    system.autoUpgrade.enable = lib.mkForce false;

    services = {
      getty = {
        autologinUser = null;
        loginProgram = "/run/current-system/sw/bin/sleep";
        loginOptions = "infinity";
        extraArgs = ["--skip-login"];
        greetingLine = "DEVICE READY FOR ONBOARDING OR RECOVERY";
        helpLine = lib.mkForce ''
          Help: https://github.com/elias-online/aviary
          IPv4 Address: \4
          Hostname: ${config.networking.hostName}
          
          Wired connections take priority over wireless.
          DHCP addresses take priority over APIPA.
          A loopback address indicates no connection.
          
          Press <CTRL+C> to refresh...
        '';
      };
    };  

    # Some seemingly usefull config pulled from NixOS live media

    environment.variables.GC_INITIAL_HEAP_SIZE = "1M";

    boot.kernel.sysctl."vm.overcommit_memory" = "1";

    system.extraDependencies = with pkgs; [stdenv];

    environment.etc."systemd/pstore.conf".text = ''
      [PStore]
      Unlink=no
    '';

    nixpkgs.overlays = lib.mkDefault [
      (_: prev: {
        mbrola-voices = prev.mbrola-voices.override {
          languages = ["*1"];
        };
      })
    ];
  };
}
