{ ... }: let
  primary =
    if builtins.pathExists /tmp/egg-drive
    then (builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive))
    else "/dev/vdb";
  name =
    if builtins.pathExists /tmp/egg-drive-name
    then (builtins.replaceStrings ["\n"] [""] (builtins.readFile /tmp/egg-drive-name))
    else "egg";
in {
  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = ["size=2G" "defaults" "mode=755"];
    };

    disk.primary = {
      device = primary;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            name = "esp-" + name;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["defaults" "umask=0077"];
            };
          };

          root = {
            size = "100%";
            name = "luks-" + name;
            content = {
              type = "luks";
              name = "disk-primary-luks-btrfs-" + name;
              settings = {
                allowDiscards = true;
                fallbackToPassword = false; # Doesn't seem to modify /etc/crypttab in initird
                keyFile = "/luks-key";
              };
              additionalKeyFiles = [ "/luks-key-recovery" ];
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "nix" = {
                    mountOptions = ["compress=zstd" "noatime"];
                    mountpoint = "/nix";
                  };
                  "persist" = {
                    mountOptions = ["compress=zstd" "noatime"];
                    mountpoint = "/persist";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
