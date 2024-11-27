### HARDWARE ###
# CPU: Intel Celeron 3215U @ 1.7GHz
# MBD: ASUS CN62
# RAM: 2x2GB DDR3L 1600MHz
# STO: 128 GB SATA SSD
################

{ config, inputs, modulesPath, ... }: {

  sops.secrets.quail-ts-key = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    (import ./hardware/single.nix {
      primary = "/dev/disk/by-id/ata-NT-128_2242_0024097000629";
    })

    (import ./hardware/vpn.nix {
      tskey = config.sops.secrets.quail-ts-key.path;
    })
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
    "usbhid"
    "usb_storage"
    "xhci_pci"
  ];

  boot.kernelModules = [ "kvm-intel" ];

  system.stateVersion = "24.05";
  networking.hostName = "quail";
  time.timeZone = "America/Denver";
}
