{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit ( lib )
    mkDefault
    mkForce
  ;

  host = config.networking.hostName;

in { 

  config = {

    boot.initrd.availableKernelModules = [
      "usb_storage"

      # Best effort at supporting as many ethernet chipsets
      # as possbile, more than likely missing some
      "asix"
      "atl1c"
      "atlantic"
      "cdc_ether"
      "e1000"
      "e1000e"
      "bnx2"
      "bnx2x"
      "broadcom"
      "cxgb4"
      "forcedeth"
      "i40e"
      "iavf"
      "igb"
      "ixgbe"
      "mcs7830"
      "pcnet32"
      "r8152"
      "r8169"
      "sky2"
      "tg3"
      "tulip"
      "usbnet"
      "virtio-net"

      # Best effort at supporting as many wifi chipsets
      # as possible, more than likely missing some
      "iwlmvm"
      "iwlwifi"
      "rtl8192ce"
      "rtl8192cu"
      "rtl8723be"
      "rtl8188ee"
      "rtl8xxxu"
      "rtlwifi"
      "brcmsmac"
      "brcmfmac"
      "ath9k"
      "ath11k"
      "ath5k"
      "mt76"
      "mt7601u"
      "rt2800pci"
      "rt2800usb"
      "zd1211rw"
      "b43"
      "p54usb"
    ];

    systemd = {

      targets.multi-user.wants = [ "wpa_supplicant-recovery.service" ];

      services = {
      
        "wpa_supplicant-recovery" = {
          description = "WPA supplicant daemon (for interface wifi0)";
          requires = [ "sys-subsystem-net-devices-wifi0.device" ];
          after = [ "sys-subsystem-net-devices-wifi0.device" ];
          before = [ "network.target" ];
          wants = [ "network.target" ]; # TODO Does this make sense given before = [ "network.target" ] also?
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "simple";
          script = "/run/current-system/sw/bin/wpa_supplicant -c /persist/wpa_supplicant-wifi0.conf -i wifi0";
        };

        tailscaled.preStop = "/run/current-system/sw/bin/tailscale logout";
      };
    };

    security.sudo.wheelNeedsPassword = false;
    security.polkit.enable = true; # reboot without password

    # Recovery devices should not be updated as they are ephemeral and impure.
    system.autoUpgrade.enable = mkForce false;

    services = {
      getty = {
        autologinUser = null;
        loginProgram = "/run/current-system/sw/bin/sleep";
        loginOptions = "infinity";
        extraArgs = [ "--skip-login" ];
        greetingLine = "DEVICE READY FOR ONBOARDING OR RECOVERY";
        helpLine = mkForce ''
          https://github.com/ilyx-me/aviary
          IPv4 Address: \4
          Hostname: ${host}
          
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

    system.extraDependencies = [ pkgs.stdenv ];

    environment.etc."systemd/pstore.conf".text = ''
      [PStore]
      Unlink=no
    '';

    nixpkgs.overlays = mkDefault [
      (_: prev: {
        mbrola-voices = prev.mbrola-voices.override {
          languages = ["*1"];
        };
      })
    ];
  };
}
