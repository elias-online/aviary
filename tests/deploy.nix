{
  inputs,
  nixpkgs,
  self,
  ...
}: let
  config = self.checks.x86_64-linux.deploy.nodes.machine;
  lib = nixpkgs.lib;
in {
  name = "deploy-test";

  meta.timeout = 600;

  node.specialArgs = {inherit inputs;};
  nodes = {
    machine = _: {
      imports = [
        self.nixosModules.recovery
        (import ./users/headless.nix {inherit config inputs lib;})
      ];

      virtualisation.memorySize = 3072;
      virtualisation.emptyDiskImages = [4096];
      virtualisation.useEFIBoot = true;

      sops = {
        secrets = {
          "test-a-ssh-user" = {
            mode = lib.mkVMOverride "0400";
            owner = lib.mkVMOverride "root";
            path = lib.mkVMOverride "/root/.ssh/id_ed25519";
          };
          "test-a-ssh-user-pub" = {};
        };
      };

      systemd.tmpfiles.rules = ["d /root/.ssh 0700 root root -"];

      users.users.root.openssh.authorizedKeys = let
        root-egg =
          builtins.replaceStrings ["\n"] [""]
          (builtins.readFile config.sops.secrets."test-a-ssh-user-pub".path);
      in {
        keys = [root-egg];
      };

      networking.hostName = "deploy-test";
    };
  };

  testScript = ''
    # Ensure nixos-anywhere deployment works
    machine.copy_from_host("/home/1000/aviary/", "/tmp/") # TODO This path needs to be dehardcoded but challenging
    machine.execute("echo passwordHash > /luks-key")
    machine.execute("nixos-anywhere -f ./aviary#deploy-test --option pure-eval false --phases disko,install root@localhost", True, False, None)

    # Clean up tailscale ephemeral node
    machine.execute("tailscale logout")
  '';
}
