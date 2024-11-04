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
	    };
          };
        };
      };
    };
  };
}
