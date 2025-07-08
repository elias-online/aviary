#### HARDWARE ###
# CPU: Intel 9900k
# MBD: Asus ROG Maximus XI Hero Wifi
# RAM: GSkills 32x4GB 3200MHz
# GPU: Nvidia 3090
# STO: Intel Optaine 128GB NVME
# STO: WD 2TB NVME
# MON: Samsung 3440x1440 100Hz
#################
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

    ./modules/nvidia.nix

    #./modules/partdouble.nix
    ./modules/partsinglequota.nix
  ];

  config = {
    
    sops.secrets = {
      "cardinal-drive-primary" = {
        mode = "0440";
      	owner = config.users.users."1000".name;
	      group = "admin";
      };
      "cardinal-drive-secondary" = {
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

    boot.kernelModules = ["kvm-intel"];

    networking.hostName = "cardinal";
    time.timeZone = "America/Los_Angeles";

    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
    # system.stateVersion = "24.05";
    home-manager.users."1000".home.stateVersion = config.system.stateVersion;
  };
}
