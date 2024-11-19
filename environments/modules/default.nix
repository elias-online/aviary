{ config, lib, pkgs, ... }: {

  imports = [
    ./bluetooth.nix
    ./bootload.nix
    ./flatpak.nix
    ./gnome.nix
    ./impermanence.nix
    ./lukspwdsync.nix
    ./network.nix
    ./package.nix
    ./pipewire.nix
    ./plymouth.nix
    ./powerprofile.nix
    ./print.nix
    ./update.nix
  ];

  sops = {
    validateSopsFiles = false;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/keys/age_host_key";
      generateKey = true;
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  environment.systemPackages = [
    pkgs.age
    pkgs.disko
    pkgs.git
    pkgs.nixos-anywhere
    pkgs.rsync
    pkgs.sops
    pkgs.ssh-to-age

    (lib.hiPrio (pkgs.runCommand "nvim.desktop-hide" { } ''
      mkdir -p "$out/share/applications"
      cat "${config.programs.neovim.finalPackage}/share/applications/nvim.desktop" \
        > "$out/share/applications/nvim.desktop"
      echo "Hidden=1" >> "$out/share/applications/nvim.desktop"
    ''))
  ];

  programs = { 
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    nano.enable = false;
  };

  documentation.doc.enable = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  users.mutableUsers = false; 
  security.sudo.extraConfig = "Defaults lecture=never"; 
}
