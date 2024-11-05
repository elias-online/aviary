{ environment ? throw "Set the environment", ... }: {
  
  imports = [
    ./minimal.nix
  ];

  minimal.enable = if builtins.toString environment == "minimal" then true else false;
}
