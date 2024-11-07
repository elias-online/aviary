{ config, lib, ... }: {

  options.lukspwdsync.enable = lib.mkEnableOption "enable syncronizing luks pwd with system pwd";

  config = lib.mkIf config.lukspwdsync.enable {

    systemd.services."lukspwdsync" = {
      enable = true;
      description = "Syncronize luks passkey with user password";  
      serviceConfig = {
        StandardOutput = "null";
	StandardError = "null";
      };

      script = ''
	oldKey=$(cat ${config.sops.secrets.password-previous.path})
	newKey=$(cat ${config.sops.secrets.password.path})
	primaryDevice=$(/run/current-system/sw/bin/cryptsetup status /dev/mapper/luksbtrfs \
	    | grep device: | sed -n 's/^  device:  //p')
	secondaryDevice=$(/run/current-system/sw/bin/cryptsetup status /dev/mapper/luksbtrfshome \
	    | grep device: | sed -n 's/^  device:  //p')


	printf "%s\n%s\n%s\n" "$oldKey" "$newKey" "$newKey" \
	    | /run/current-system/sw/bin/cryptsetup luksChangeKey "$primaryDevice"

	if [ -n "$secondaryDevice" ]; then
	    printf "%s\n%s\n%s\n" "$oldKey" "$newKey" "$newKey" \
	        | /run/current-system/sw/bin/cryptsetup luksChangeKey "$secondaryDevice"
	fi
      '';

      serviceConfig.Type = "oneshot";
    };
  };
}
