{ environment ? throw "Set the environment", ... }: {
  
  imports = [
    ./desktop.nix
    ./minimal.nix
  ];

  desktop.enable = if builtins.toString environment == "desktop" then true else false;
  minimal.enable = if builtins.toString environment == "minimal" then true else false;
}
