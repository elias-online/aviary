{ config, lib, ... }: {

  options.secrets.enable = lib.mkEnableOption "enable secrets";
  
  config = lib.mkIf config.secrets.enable {

    sops = {
      validateSopsFiles = false;
      age = {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
	keyFile = "/var/keys/age_host_key";
	generateKey = true;
      };
    };
  };
}
