{
  inputs,
  nixpkgs,
  pkgs,
  self,
  ...
}: let
  config = self.checks.x86_64-linux.egg.nodes.machine;
  lib = nixpkgs.lib;

  passwordHash =
    builtins.replaceStrings ["\n"] [""]
    (builtins.readFile config.sops.secrets."test-a-password-hash".path);
in {
  name = "egg-test";
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
      self.nixosModules.recovery
      (import ./users/headless.nix {inherit config inputs lib;})
    ];
    testing.initrdBackdoor = true;

    networking.hostName = "egg";

    boot.initrd.systemd.packages = with pkgs; [curl unixtools.ping];
    boot.initrd.systemd.initrdBin = with pkgs; [curl unixtools.ping util-linux gnugrep];
  };

  bootCommands = ''
    # Ensure initrd internet connection
    machine.wait_for_unit("tailscaled.service")
    machine.succeed("systemctl is-active dbus")
    machine.succeed("systemctl is-active systemd-resolved")
    machine.succeed("systemctl is-active systemd-networkd")
    machine.succeed("ping -c 3 1.1.1.1")
    machine.succeed("ping -c 3 100.100.100.100")
    machine.succeed("curl google.com")

    # Ensure initrd vpn units
    machine.succeed("systemctl is-active sshd")
    machine.succeed("systemctl is-active tailscaled")

    # Ensure decryption shell for root
    machine.succeed("cat /etc/passwd | grep root | grep systemd-tty-ask-password-agent")

    machine.wait_for_text("[Pp]assphrase for")
    machine.send_chars("password\n")
  '';

  extraTestScript = ''
    machine.switch_root()

    # Ensure correct partitioning
    machine.succeed("cryptsetup isLuks /dev/vda2")
    machine.succeed("btrfs subvolume list /nix | grep -qs 'path nix$'")
    machine.succeed("btrfs subvolume list /persist | grep -qs 'path persist$'")
    machine.succeed("mountpoint /")
    machine.succeed("mountpoint /boot")

    # Ensure internet connection
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl is-active dbus")
    machine.succeed("systemctl is-active systemd-resolved")
    machine.succeed("systemctl is-active systemd-networkd")
    machine.succeed("ping -c 3 1.1.1.1")
    machine.succeed("ping -c 3 100.100.100.100")
    machine.succeed("curl google.com")

    # Ensure vpn units
    machine.succeed("systemctl is-active sshd")
    machine.succeed("systemctl is-active tailscaled")

    # Ensure no login on tty
    machine.send_chars("root\n")
    try:
        machine.wait_for_x(3)
    except Exception:
        pass
    machine.fail("last | grep tty1 | grep root")

    # Clean up tailscale ephemeral node
    machine.execute("tailscale logout")
  '';
}
