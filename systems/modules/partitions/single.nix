{
  ...
}:

{

  imports = [
    ./default.nix
  ];
  
  config = {

    disko.devices.disk.primary.content.partitions.root.content.content.subvolumes = {
      
      "root" = {
        mountOptions = [ "compress=zstd" "noatime" ];
        mountpoint = "/";
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
}
