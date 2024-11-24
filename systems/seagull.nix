#### HARDWARE ###
# CPU: Intel XEON E3-1220L V2 x 4
# MBD: Supermicro X9SCL
# RAM: Samsung 8x1GB EMMC
# STO: PNY 120GB SATA SSD
#################

{ inputs, modulesPath, ... }: {

  sops.secrets.seagull-ts-key = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    
    (import ./hardware/singlenas.nix {
      primary = "/dev/disk/by-id/ata-PNY_CS1311_120GB_SSD_PNY121601207901005F9";
    })

    (import ./hardware/pigeon.nix {
      tskey = config.sops.secrets.seagull-ts-key.path;
    })
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ehci_pci"
    "sd_mod"
    "usbhid"
    "usb_storage"
  ]; 

  boot.kernelModules = [ "kvm-intel" ];

  system.stateVersion = "24.05";
  networking.hostName = "seagull";
  time.timeZone = "America/Los_Angeles"; 
}
