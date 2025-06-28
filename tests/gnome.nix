{
  inputs,
  nixpkgs,
  pkgs,
  self,
  ...
}: let
  config = self.checks.x86_64-linux.deploy.nodes.machine;
  lib = nixpkgs.lib;
in {
  name = "gnome-test";

  meta.timeout = 600;

  node.specialArgs = {inherit inputs;};
  nodes = {
    machine = _: {
      imports = [
        self.nixosModules.graphical
        ./users/remote.nix
      ];

      virtualisation.memorySize = 4096;
      virtualisation.useEFIBoot = true;

      networking.hostName = "gnome-test";
    };
  };

  testScript = ''
    # Clean up tailscale ephemeral node
    machine.execute("tailscale logout")
  '';
}
