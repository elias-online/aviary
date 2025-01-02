{ config, ... }: {

  boot.initrd = {
    kernelModules = [ "r8152" ];

    systemd.network = {
      enable = true;
      networks."enp0s20f0u2u4" = {
        enable - true;
	name = "enp0s20f0u2u4";
	DHCP = "yes";
      };
    };

    #secret = {
    #  "/home/elias/.ssh/ssh_host_ed25519_key_initrd" = "/home/elias/.ssh/ssh_host_ed25519_key_initrd";
    #};

    network.ssh = {
      enable = true;
      port = 2222;
      #hostKeys = [ "/home/elias/.ssh/ssh_host_ed25519_key_initrd" ];
      authorizedKeys = config.users.users."elias".openssh.authorizedKeys.keys;
    };

    clevis = {
      enable = true;
      useTang = true;
      devices."luks".secretFile = /secret.jwe;
    };

    luks.devices."luks".device = "/dev/disk/by-id/ata-SanDisk_SD8SN8U-512G-1006_172330802078-part2"
  };

  #environment.persistence."/persist".files = [ "/secret.jwe" ];
}
