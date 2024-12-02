### HARDWARE ###
# CPU: Intel 12600k
# MBD: Asrock Z690M Phantom Gaming 4
# RAM: ADATA 8x4GB 3200MHz
# GPU: EVGA 1080Ti
# STO: Teamgroup NVME SSD 2TB
# WFI: Intel AX210NGW
################

{ config, inputs, lib, modulesPath, ... }: {

  sops.secrets.crow-ts-key = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware/nvidia.nix

    (import ./hardware/single.nix {
      primary = "/dev/disk/by-id/nvme-TEAM_TM8FP6002T_TPBF2401170060201436";
    })

    (import ./hardware/vpn.nix {
      tskey = config.sops.secrets.crow-ts-key.path;
    })
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "sr_mod"
    "usbhid"
    "usb_storage"
    "xhci_pci"
  ];

  boot.kernelModules = [ "kvm-intel" ];

  system.stateVersion = "24.05";
  networking.hostName = "crow";
  time.timeZone = "America/Denver";

  hardware.nvidia.open = lib.mkForce false;
}
