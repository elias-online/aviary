{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./modules/partbasic.nix
  ];

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
      "orinoco"
    ];
 
    networking.hostName = "egg";
    time.timeZone = "America/Los_Angeles";

    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.05";
    home-manager.users."1000".home.stateVersion = "25.05";
  };
}
