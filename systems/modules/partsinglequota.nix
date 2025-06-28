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
              fallbackToPassword = false; # Doesn't seem to modify /etc/crypttab in initrd
              keyfile = "/luks-key";
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
              postCreateHook = ''
                mount /dev/mapper/disk-primary-luks-btrfs-${config.networking.hostName} /mnt
                btrfs quota enable /mnt
                btrfs qgroup limit 64G /mnt/nix
                totalFilesystemSize=$(btrfs filesystem usage -g /mnt | grep "Device size:" | \
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
