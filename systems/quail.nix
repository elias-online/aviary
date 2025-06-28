### HARDWARE ###
# CPU: Intel Celeron 3215U @ 1.7GHz
# MBD: ASUS CN62
# RAM: 2x2GB DDR3L 1600MHz
# STO: 128GB SATA SSD
################
{
  config,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./modules/partsinglequota.nix
  ];

  config = {

    sops.secrets."quail-drive-primary" = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };
    
    boot.initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "usbhid"
      "usb_storage"
      "xhci_pci"
    ];

    boot.kernelModules = ["kvm-intel"];

    networking.hostName = "quail";
    time.timeZone = "America/Denver";

    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "24.05";
    home-manager.users."1000".home.stateVersion = "24.05";
  };
}
