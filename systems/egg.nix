{ config, lib, modulesPath, ... }:
let
  tskeystring = ""; # Put tailscale onboarding auth key here
in {

  environment = {
    etc."tskey".text = ''
      ${tskeystring}
    '';
    persistence."/persist".files = [
      "/etc/tskey"
    ];
  };

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"

    (import ./hardware/vpn.nix {
      tskey = "/etc/tskey";
    })
  ];

  boot.kernelParams = [ "copytoram" ];

  networking.hostName = "egg";
  time.timeZone = "America/Los_Angeles";

  isoImage.isoName = lib.mkForce "egg.iso";

  services = {
    getty = {
      autologinUser = lib.mkForce null;
      extraArgs = [ "-p" "-t 5" ];
      greetingLine = "<<< CONNECT WITH SSH TO ONBOARD THIS HOST >>>";
      helpLine = lib.mkForce ''
        user@local:~$ ssh nixos@\4

	Ensure an ethernet connection. An APIPA address
	will be chosen before checking for a DHCP lease.
	A loopback address indicates no ethernet link.

	For additional help see:
        https://github.com/elias-online/aviary
      '';
    };

    openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };
}
