{
  config,
  ...
}:

let

  inherit ( builtins )
    readFile
  ;

  host = config.networking.hostName;

in {

  imports = [
    ./default.nix
  ];

  config = 

  let

    secrets = config.sops.secrets;
    secretsName = config.aviary.secrets;
    
    deviceSecondary = readFile secrets.${secretsName.driveSecondary}.path; 

  in {

    disko.devices.disk = {

      primary.content.partitions.root.content.content.subvolumes = {
      
        "root" = {
          mountOptions = [ "compress=zstd" "noatime" ];
          mountpoint = "/";
        };

        "swap" = {
          swap.swapfile.size = "8G";
          mountpoint = "/.swapvol";
        };
      };

      secondary = {
        device = deviceSecondary;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            home = {
              size = "100%";
              name = "luks-" + host;
              content = {
                type = "luks";
                name = "disk-secondary-luks-btrfs-" + host;
                settings = {
                  allowDiscards = true;
                  keyFile = "/luks-key";
                };
                additionalKeyFiles = [ "/luks-key-recovery" ];
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    
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
    };
  };
}
