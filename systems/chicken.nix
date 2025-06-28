{ config, inputs, modulesPath, ... }: {

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    #./modules/partsinglequota.nix
    #./modules/partbasic.nix
    ./modules/partsingle.nix
  ];

  config = {

    sops.secrets."chicken-drive-primary" = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };

    boot.initrd.availableKernelModules = [
      "ahci"
      "iwlmvm"
      "iwlwifi"
      "sd_mod"
      "usb_storage"
      "xhci_pci"

      "i2c_hid"
      "hid_multitouch"
    ];

    boot.kernelModules = [ "kvm-intel" ];

    networking.hostName = "chicken";
    time.timeZone = "America/Los_Angeles";

    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "24.11";
    home-manager.users."1000".home.stateVersion = "24.11";
  };
}
