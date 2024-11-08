{ primary ? throw "Set the primary device", ... }: {
  disko.devices.disk.primary = {
    device = builtins.toString primary;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "defaults" "umask=0077" ];
          };            
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "luksbtrfs";
	    settings.allowDiscards = true;
            passwordFile = "/keyfile";
            content = {
              type = "btrfs";
	      extraArgs = [ "-f" ];
	      subvolumes = {
	        "root" = {
	          mountOptions = [ "compress=zstd" "noatime" ];
	          mountpoint = "/";
	        };
	        "persist" = {
	          mountOptions = [ "compress=zstd" "noatime" ];
	          mountpoint = "/persist";
	        };
	        "nix" = {
	          mountOptions = [ "compress=zstd" "noatime" ];
	          mountpoint = "/nix";
	        };
	        "swap" = {
	          swap.swapfile.size = "8G";
	          mountpoint = "/.swapvol";
	        };
	        "home" = {
	          mountOptions = [ "compress=zstd" "noatime" ];
	          mountpoint = "/home";
	        };
	      };
	      postCreateHook = ''
	        mount /dev/mapper/luksbtrfs /mnt
	        btrfs quota enable /mnt
                btrfs qgroup limit 64G /mnt/nix
		totalFilesystemSize=$(btrfs filesystem usage /mnt | grep "Device size:" | \
		    sed -n 's/Device size:[[:space:]]*\([0-9.]*\)GiB/\1/p')
		homeQuotaSize=$(awk "BEGIN {print int($totalFilesystemSize - 72)}")
	      	btrfs qgroup limit ''${homeQuotaSize}G /mnt/home
		umount /mnt
	      '';
	    };
          };
        };
      };
    };
  };
}
