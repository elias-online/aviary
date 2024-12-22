{ config, ... }: {

  boot = {
    kernelModules = [ "igb" ];

    initrd = {
      kernelModules = [ "igb" ];

      systemd = {
	network = {
	  enable = true;
	  networks."enp0s20f0u2u4" = {
	    enable = true;
	    name = "enp0s20f0u2u4";
	    DHCP = "yes";
	  };
	};
      };

      secrets = {
        "/secrets/boot/ssh/ssh_host_ed25519_key" = "/etc/ssh/ssh_host_ed25519_key";
      };

      network = {
        ssh = {
	  enable = true;
	  port = 2222;
	  hostKeys = [ "/secrets/boot/ssh/ssh_host_ed25519_key" ];
	  authorizedKeys = config.users.users."elias".openssh.authorizedKeys.keys;
	};
      };
    };
  };
}
