{
  inputs,
  nixpkgs,
  self,
  ...
}: let
  config = self.checks.x86_64-linux.egg.nodes.machine;
  lib = nixpkgs.lib;

  username =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."test-a-username".path);

  passwordHash =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."test-a-password-hash".path);
in {
  name = "login-test";
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
    machine.send_chars("${username}\n")
    try:
        machine.wait_for_x(3)
    except Exception:
        pass
    machine.send_chars("password\n")
    try:
        machine.wait_for_x(3)
    except Exception:
        pass
    machine.succeed("last | grep tty1 | grep test-a")

    # Clean up tailscale ephemeral node
    machine.execute("tailscale logout")
  '';
}
