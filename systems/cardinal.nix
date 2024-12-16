#### HARDWARE ###
# CPU: Intel 9900k
# MBD: Asus ROG Maximus XI Hero Wifi
# RAM: GSkills 32x4GB 3200MHz
# GPU: Nvidia 3090
# STO: Intel Optaine 128GB NVME
# STO: WD 2TB NVME
# MON: Samsung 3440x1440 100Hz
#################

{ config, inputs, modulesPath, ... }: {

  sops.secrets.cardinal-ts-key = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    
    ./hardware/nvidia.nix

    (import ./hardware/dual.nix {
      primary = "/dev/disk/by-id/nvme-INTEL_SSDPEK1A118GA_PHOC216600N2118B";
      secondary = "/dev/disk/by-id/nvme-WDS200T3X0C-00SJG0_20319A800143";
    })

    (import ./hardware/vpn.nix {
      tskey = config.sops.secrets.cardinal-ts-key.path;
    })
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usbhid"
    "usb_storage"
    "xhci_pci"
  ]; 

  boot.kernelModules = [ "kvm-intel" ];

  system.stateVersion = "24.05";
  networking.hostName = "cardinal";
  time.timeZone = "America/Los_Angeles"; 
}
