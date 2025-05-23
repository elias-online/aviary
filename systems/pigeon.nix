#### HARDWARE ###
# CPU: AMD EPYC 7551P 32c
# MBD: Supermicro H11SSL-i
# RAM: Samsung 32x4GB ECC
# STO: Intel Optane P1600X NVME SSD 58x2GB
# ETH: AQTION AQC107 10Gbps
#################

{ config, inputs, modulesPath, ... }: {

  sops.secrets.pigeon-ts-key = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    (import ./hardware/singleserver.nix {
      primary = "/dev/disk/by-id/nvme-INTEL_SSDPEK1A058GA_BTOC14120XX4058A";

      ### BACKUP DRIVE ###
      #primary = "/dev/disk/by-id/nvme-INTEL_SSDPEK1A058GA_BTOC14120Y05058A";
      ####################
    })

    (import ./hardware/pigeon.nix {
      tskey = config.sops.secrets.pigeon-ts-key.path;
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

  boot.kernelModules = [ "kvm-amd" ];

  system.stateVersion = "24.05";
  networking.hostName = "pigeon";
  time.timeZone = "America/Los_Angeles";
}
