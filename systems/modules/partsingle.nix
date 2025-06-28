{config, ...}: let
  primary =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets.${config.networking.hostName + "-drive-primary"}.path);
in {
  disko.devices.disk.primary = {
    device = primary;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "2048M";
          type = "EF00";
          name = "esp-" + config.networking.hostName;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["defaults" "umask=0077"];
          };
        };
        root = {
          size = "100%";
          name = "luks-" + config.networking.hostName;
          content = {
            type = "luks";
            name = "disk-primary-luks-btrfs-" + config.networking.hostName;
            settings = {
              allowDiscards = true;
              fallbackToPassword = false; # Doesnt seem to modify /etc/crypttab in initrd
              keyFile = "/luks-key";
            };
            additionalKeyFiles = [ "/luks-key-recovery" ];
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "root" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/";
                };
                "persist" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/persist";
                };
                "nix" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/nix";
                };
                "swap" = {
                  swap.swapfile.size = "8G";
                  mountpoint = "/.swapvol";
                };
                "home" = {
                  mountOptions = ["compress=zstd" "noatime"];
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
