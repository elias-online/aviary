{
  config,
  inputs,
  lib,
  ...
}: let
  secrets = builtins.toString inputs.secrets;
in {
  config = {
    sops = {
      defaultSopsFile = lib.mkVMOverride "${secrets}/tests.yaml";
      secrets."test-a-ssh-host" = {};
    };

    # WARNING: writes public copy of the test ssh host key to store
    environment.etc."ssh/ssh_host_ed25519_key" = {
      text = builtins.readFile config.sops.secrets."test-a-ssh-host".path;
      mode = "0400";
    };
    usersbase.usernameSecret = "test-a-username";
    usersbase.descriptionSecret = "test-a-description";
    usersbase.passwordHashSecret = "test-a-password-hash";
    usersbase.passwordHashPreviousSecret = "test-a-password-hash-previous";
    usersbase.sshAdminSecret = "test-a-ssh-admin";
    usersbase.sshAdminPubSecret = "test-a-ssh-admin-pub";
    usersbase.sshUserSecret = "test-a-ssh-user";

    vpn.tsKey = "test-a-ts";

    home-manager.users."1000".home.stateVersion = "24.11";

    users.users."1000" = {
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = ["none"];
    };
  };
}
