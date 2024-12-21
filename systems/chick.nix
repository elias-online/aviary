{ config, inputs, modulesPath, ... }: {

  sops.secrets.chick-ts-key = {};
  sops.secrets.chick-ts-initrd = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    (import ./hardware/single.nix {
      primary = "/dev/disk/by-id/ata-SanDisk_SD8SN8U-512G-1006_172330802078"; #Silver Test Laptop
    })

    (import ./hardware/vpn.nix {
      tskey = config.sops.secrets.chick-ts-key.path;
    })
    
    ./hardware/initrd-test.nix
    #./hardware/vpn-initrd2.nix
    #./hardware/boot.nix
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
    "usb_storage"
    "xhci_pci"
  ];

  boot.kernelModules = [ "kvm-intel" ];

  system.stateVersion = "24.11";
  networking.hostName = "chick";
  time.timeZone = "America/Los_Angeles";

  #remote-machine.boot.tailscaleUnlock = {
  #  enable = true;
  #  tailscaleStatePath = config.sops.secrets.chick-ts-initrd.path;
  #};
}
