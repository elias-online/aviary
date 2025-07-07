{config, ...}: let
  primary =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets.${config.networking.hostName + "-drive-primary"}.path);
  secondary =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets.${config.networking.hostName + "-drive-secondary"}.path);
  hostname = config.networking.hostName;
in {
  boot.initrd.systemd.services = {
    ${"systemd-cryptsetup@disk\\x2dsecondary\\x2dluks\\x2dbtrfs\\x2d" + hostname} = {
      enable = true;
      wants = ["${"systemd-cryptsetup@disk\\x2dprimary\\x2dluks\\x2dbtrfs\\x2d" + hostname + ".service"}"];
      overrideStrategy = "asDropin";
      serviceConfig = {

        # Explicity overwrite generated unit's ExecStart to run systemd-cryptsetup
        # in headless mode to prevent password fallback as Disko settings.fallbackToPassword = false
        # doesn't appear to properly configure /etc/crypttab in initrd
        ExecStart = [
          ""
          "systemd-cryptsetup attach 'disk-secondary-luks-btrfs-${hostname}' '/dev/disk/by-partlabel/disk-secondary-luks-${hostname}' '/luks-key' 'discard,headless'"
        ]; 
      };
      unitConfig.DefaultDependencies = "no";
    };
  };

  disko.devices.disk = {
    primary = {
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
                };
              };
            };
          };
        };
      };
    };

    secondary = {
      device = secondary;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          home = {
            size = "100%";
            name = "luks-" + config.networking.hostName;
            content = {
              type = "luks";
              name = "disk-secondary-luks-btrfs-" + config.networking.hostName;
              settings = {
                allowDiscards = true;
                fallbackToPassword = false; # Doesn't seem to modify /etc/crypttab in initrd
                keyFile = "/luks-key";
              };
              additionalKeyFiles = [ "/luks-key-recovery" ];
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
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
  };
}
