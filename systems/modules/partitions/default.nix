{ 
  config,
  lib,
  ...
}:

let

  inherit ( builtins )
    pathExists
    readFile
  ;

  inherit ( lib )
    mkOption
  ;

  inherit ( lib.types )
    nullOr
    str
  ;

  host = config.networking.hostName;

in {

  options.aviary.secrets = {

    drivePrimary = mkOption {
      type = nullOr str;
      default = host + "-drive-primary";
      example = "hostname-drive-primary";
      description = "SOPS-Nix secret storing the system primary drive";
    };
  };

  config = 

  let

    secrets = config.sops.secrets;
    secretsName = config.aviary.secrets;

    defaultPermissions = {
      mode = "0440";
      owner = config.users.users."1000".name;
      group = "admin";
    };
  
    devicePrimary = if pathExists /tmp/egg-drive then (
      readFile /tmp/egg-drive
    ) else readFile secrets.${secretsName.drivePrimary}.path;

  in {

    sops.secrets."${secretsName.drivePrimary}" = defaultPermissions;

    disko.devices.disk.primary = {
      device = devicePrimary;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          
          esp = {
            size = "2048M";
            type = "EF00";
            name = "esp-" + host;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" "umask=0077" ];
            };
          };

          root = {
            size = "100%";
            name = "luks-" + host;
            content = {
              type = "luks";
              name = "disk-primary-luks-btrfs-" + host;
              settings = {
                allowDiscards = true; 
                keyFile = "/luks-key";
              };
              additionalKeyFiles = [ "/luks-key-recovery" ];
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "persist" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
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
