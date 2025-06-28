#### HARDWARE ###
# CPU: AMD EPYC 7551P 32c
# MBD: Supermicro H11SSL-i
# RAM: Samsung 4x32GB ECC
# STO: Intel Optane P1600X NVME SSD 58x2GB
# ETH: AQTION AQC107 10Gbps
#################
{
  config,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ./modules/partsingle.nix
  ];

  config = {

    sops.secrets = {
      "pigeon-drive-primary" = {
        mode = "0440";
	owner = config.users.users."1000".name;
	group = "admin";
      };
      "pigeon-drive-secondary" = {
        mode = "0440";
	owner = config.users.users."1000".name;
	group = "admin";
      };
    };
    
    boot.initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "usbhid"
      "usb_storage"
      "xhci_pci"
    ];

    boot.kernelModules = ["kvm-amd"];

    networking.hostName = "pigeon";
    time.timeZone = "America/Los_Angeles";

    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "24.05";
    home-manager.users."1000".home.stateVersion = "24.05";
  };
}
