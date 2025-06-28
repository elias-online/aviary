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
        self.nixosModules.graphicalHyprland
        ./users/remote.nix
      ];

      virtualisation.memorySize = 4096;
      virtualisation.useEFIBoot = true;
      virtualisation.resolution = { x = 1920; y = 1080; };
      virtualisation.cores = 4;

      networking.hostName = "hyprland-test";
    };
  };

  testScript = ''
    # Clean up tailscale ephemeral node
    machine.execute("tailscale logout")
  '';
}
