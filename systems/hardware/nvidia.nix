{ config, inputs, pkgs, ... }: {

  imports = [
    inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
  ];

  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  hardware.nvidia = {
    open = true;
    powerManagement.enable = true;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta; #change to "stable" for v550
  };

  services.xserver.displayManager.gdm.wayland = false;
}
