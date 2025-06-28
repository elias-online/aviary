### HARDWARE ###
# CPU: Intel 12600k
# MBD: Asrock Z690M Phantom Gaming 4
# RAM: ADATA 4x8GB 3200MHz
# GPU: EVGA 1080Ti
# STO: Teamgroup NVME SSD 2TB
# WFI: Intel AX210NGW
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

    ./modules/nvidia.nix
  ];

  config = {

    sops.secrets."crow-drive-primary" = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };
    
    boot.initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "sr_mod"
      "usbhid"
      "usb_storage"
      "xhci_pci"
    ];

    boot.kernelModules = ["kvm-intel"];

    hardware.nvidia.open = lib.mkForce false;

    networking.hostName = "crow";
    time.timeZone = "America/Denver";

    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "24.05";
    home-manager.users."1000".home.stateVersion = "24.05";
  };
}
