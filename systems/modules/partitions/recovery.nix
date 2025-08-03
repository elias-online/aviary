{
  ...
}:

{

  imports = [
    ./default.nix
  ];

  config = {
    
    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [ "size=2G" "defaults" "mode=755" ];
      };
    };
  };
}
