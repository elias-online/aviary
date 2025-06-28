#### HARDWARE ###
# CPU: Intel XEON E3-1220L V2 x 4
# MBD: Supermicro X9SCL
# RAM: Samsung 8x1GB EMMC
# STO: PNY 120GB SATA SSD
#################

{ config, inputs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    
    ./modules/partsingle.nix
  ];

  config = {

    sops.secrets."seagull-drive-primary" = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };
 
    boot.initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "sd_mod"
      "usbhid"
      "usb_storage"
    ]; 

    boot.kernelModules = [ "kvm-intel" ];

    networking.hostName = "seagull";
    time.timeZone = "America/Los_Angeles";

    nixpkgs.hostPLatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "24.05";
    home-manager.users"1000".home.stateVersion = "24.05";
  };
}
