{
  inputs,
  nixpkgs,
  self,
  ...
}: let
  config = self.checks.x86_64-linux.egg.nodes.machine;
  lib = nixpkgs.lib;

  passwordHash =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."test-a-password-hash".path);
in {
  name = "syncluks-test";
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

    networking.hostName = "egg";
  };

  bootCommands = ''
    machine.wait_for_text("[Pp]assphrase for")
    machine.send_chars("password\n")
  '';

  extraTestScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("printf '%s' '$y$j9T$5a07Drp/2IMhGa78Fq372/$upoNR1XP7pTiO3ghuLw15gurRh0cNLZrOYc7T6EWnN7' > /run/secrets/test-a-password-hash")
    machine.succeed("systemctl start syncluks.service")

    machine.shutdown()
    machine.start()

    machine.wait_for_text("[Pp]assphrase for")
    machine.send_chars("new-password\n")
    machine.wait_for_unit("multi-user.target")
  '';
}
