{
  inputs,
  nixpkgs,
  self,
  ...
}: let
  #secrets = builtins.toString inputs.secrets;
  config = self.checks.x86_64-linux.egg.nodes.machine;
  lib = nixpkgs.lib;

  passwordHash =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."test-a-password-hash".path);
in {
  name = "impermanence-test";
  enableOCR = true;

  disko-config = import ../systems/modules/partbasic.nix {inherit config;};

  extraInstallerConfig = {
    imports = [
      self.nixosModules.default
      (import ./users/default.nix {inherit config inputs lib;})
    ];

    systemd.tmpfiles.settings."50-luks-pwd"."/luks-key".f.argument = passwordHash;
  };

  extraSystemConfig = {
    imports = [
      self.nixosModules.default
      (import ./users/default.nix {inherit config inputs lib;})
    ];

    environment.persistence."/persist".files = ["/toBeKept"];

    networking.hostName = "egg";
  };

  bootCommands = ''
    machine.wait_for_text("[Pp]assphrase for")
    machine.send_chars("password\n")
  '';

  extraTestScript = ''
    machine.wait_for_unit("default.target")
    machine.succeed("mkdir /mnt")
    machine.succeed("mount /dev/mapper/disk-primary-luks-btrfs-egg /mnt")
    machine.succeed("mkdir -p /mnt/old_roots")

    machine.succeed("btrfs subvolume create /mnt/old_roots/2000-01-1_00:00:00")
    machine.succeed("touch -d '2000-01-01 00:00:00' /mnt/old_roots/2000-01-1_00:00:00/toBeRemoved")
    machine.succeed("touch -d '2000-01-01 00:00:00' /mnt/old_roots/2000-01-1_00:00:00")

    machine.succeed("date -d '15 days ago' '+%Y-%m-%-d_%H:%M:%S' > /persist/timestamp1")
    machine.succeed("btrfs subvolume create /mnt/old_roots/$(cat /persist/timestamp1)")
    machine.succeed("touch -d '15 days ago' /mnt/old_roots/$(cat /persist/timestamp1)/toBeRemoved")
    machine.succeed("touch -d '15 days ago' /mnt/old_roots/$(cat /persist/timestamp1)")

    machine.succeed("touch /toBeRemoved")

    machine.succeed("date -d '14 days ago' '+%Y-%m-%-d_%H:%M:%S' > /persist/timestamp2")
    machine.succeed("btrfs subvolume create /mnt/old_roots/$(cat /persist/timestamp2)")
    machine.succeed("touch -d '14 days ago' /mnt/old_roots/$(cat /persist/timestamp2)/toBeKept")
    machine.succeed("touch -d '14 days ago' /mnt/old_roots/$(cat /persist/timestamp2)")

    machine.succeed("date '+%Y-%m-%-d_%H:%M:%S' > /persist/timestamp3")
    machine.succeed("btrfs subvolume create /mnt/old_roots/$(cat /persist/timestamp3)")
    machine.succeed("touch /mnt/old_roots/$(cat /persist/timestamp3)/toBeKept")
    machine.succeed("touch /mnt/old_roots/$(cat /persist/timestamp3)")

    machine.succeed("touch /toBeKept")

    machine.shutdown()
    machine.start()

    machine.wait_for_text("[Pp]assphrase for")
    machine.send_chars("password\n")

    machine.wait_for_unit("default.target")

    machine.succeed("mkdir /mnt")
    machine.succeed("mount /dev/mapper/disk-primary-luks-btrfs-egg /mnt")

    machine.fail("[ -e /mnt/old_roots/2000-01-1_00:00:00/toBeRemoved ]")
    machine.fail("[ -e /mnt/old_roots/$(cat /persist/timestamp1)/toBeRemoved ]")
    machine.fail("[ -e /toBeRemoved ]")
    machine.succeed("[ -e /mnt/old_roots/$(cat /persist/timestamp2)/toBeKept ]")
    machine.succeed("[ -e /mnt/old_roots/$(cat /persist/timestamp3)/toBeKept ]")
    machine.succeed("[ -e /toBeKept ]")
    machine.succeed("[ -e /persist/toBeKept ]")
  '';
}
