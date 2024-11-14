{ config, inputs, lib, pkgs, ... }: {

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraPlugins = [ pkgs.vimPlugins.adwaita-nvim ];
    colorscheme = "adwaita";
    plugins.treesitter.enable = true;
    plugins.lualine.enable = true;
  };

  home.packages = [
    (lib.hiPrio (pkgs.runCommand "nvim.desktop-hide" { } ''
      mkdir -p "$out/share/applications"
      cat "${config.programs.nixvim.finalPackage}/share/applications/nvim.desktop" \
        > "$out/share/applications/nvim.desktop"
      echo "Hidden=1" >> "$out/share/applications/nvim.desktop"
    ''))
  ];
}
