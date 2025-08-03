{
  ...
}:

let
  
  inherit ( builtins )
    pathExists
    readFile
  ;

in {
  
  imports = [
    ./modules/partitions/recovery.nix
  ];

  config = {

    aviary.secrets = {
      drivePrimary = "egg-drive-primary";
      luksHash = "egg-luks-hash";
      platform = "egg-platform";
      stateVersion = "egg-state-version";
      sshAdmin = "egg-ssh-admin";
      sshAdminPub = "egg-ssh-admin-pub";
      sshHostInitrd = "egg-ssh-host-initrd";
      sshUser = "egg-ssh-user";
      timezone = "egg-timezone";
      ts = "egg-ts";
      tsInitrd = "egg-ts-initrd";
    };

    networking.hostName = if pathExists /tmp/egg-drive-name then (
      readFile /tmp/egg-drive-name
    ) else "egg";
  };
}
