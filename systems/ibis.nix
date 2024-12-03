#### HARDWARE ###
# CPU: Intel 11300H
# MBD: Microsoft Surface Laptop Studio 1
# RAM: Integrated 16GB
# STO: Predator 512GB NVME SSD
# MON: Integrated 2400x1600 120Hz Touchscreen
#################

{ config, inputs, pkgs, modulesPath, ... }: {

  sops.secrets.ibis-ts-key = {};

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.microsoft-surface-pro-intel
    inputs.hardware.nixosModules.microsoft-surface-common

    (import ./hardware/single.nix {
      primary = "/dev/disk/by-id/nvme-SAMSUNG_MZ9LQ256HBJQ-00000_S595NF0R372569";
      #primary = "/dev/disk/by-id/nvme-Predator_SSD_GM7000_512GB_PSBG32530200043";
    })

    (import ./hardware/vpn.nix {
      tskey = config.sops.secrets.ibis-ts-key.path;
    })
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "sd_mod"
    "thunderbolt"
    "usb_storage"
    "xhci_pci"
    "8250_dw"
    "intel_lpss"
    "intel_lpss_pci"
    "pinctrl_tigerlake"
    "surface_aggregator"
    "surface_aggregator_hub"
    "surface_aggregator_registry"
    "surface_hid"
    "surface_hid_core"
  ];

  boot.initrd.kernelModules = [ "surface_aggregator_hub" ];
  boot.kernelModules = [ "kvm-intel" ];

  environment = {
    systemPackages = with pkgs; [
      iptsd
      libwacom-surface
    ];
    
    #Tablet file for libwacom-surface
    #From https://github.com/linux-surface/linux-surface/discussions/983
    etc."libwacom/microsoft-surface-laptop-studio.tablet".text = ''
      [Device]
      Name=Microsoft Corporation Surface Laptop Studio
      ModelName=
      DeviceMatch=virt:045e:0c1b
      PairedIDs=pci:045e:0c1b
      Class=PenDisplay
      Width=11.9402985075
      Height=7.960199005
      IntegratedIn=Display;System
      Styli=0xffffe;0xfffff;
        
      [Features]
      Stylus=true
      Touch=true
      TouchSwitch=false
      Ring=false
      NumStrips=0
      Buttons=0
      StripsNumModes=0
    '';

    etc."udev/hwdb.d/66-libwacom.hwdb".text = ''
      # hwdb entries for libwacom supported devices
      # This file is generated by libwacom, do not edit
      #
      # The lookup key is a contract between the udev rules and the hwdb entries.
      # It is not considered public API and may change.
    '';

    #Enable touchpad in slate mode
    etc."libinput/local-overrides.quirks".text = ''
      [Microsoft Surface Laptop Studio Built-In Peripherals]
      MatchName=*Microsoft Surface*
      MatchDMIModalias=dmi:*svnMicrosoftCorporation:*pnSurfaceLaptopStudio:*
      ModelTabletModeNoSuspend=1
    '';
  }; 
 
  system.stateVersion = "24.05";
  networking.hostName = "ibis";
  time.timeZone = "America/Los_Angeles";
}
