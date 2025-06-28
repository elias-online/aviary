{
  lib,
  ...
}: {
  config = {
    programs.bash.enable = true;

    programs.starship = {
      enable = true;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";

        format = lib.concatStrings [
          "[](red)"
          "$nix_shell"
          "$os"
          "$username"
          "$hostname"
          "[](fg:red bg:peach)"
          "$directory"
          "[](fg:peach bg:yellow)"
          "$git_branch"
          "$git_status"
          "[](fg:yellow bg:green)"
          "$c"
          "$rust"
          "$golang"
          "$nodejs"
          "$php"
          "$java"
          "$kotlin"
          "$haskell"
          "$python"
          "[](fg:green bg:sapphire)"
          "$docker_context"
          "$conda"
          "[](fg:sapphire bg:lavender)"
          "$time"
          "[ ](fg:lavender)"
          "$line_break$character"
        ];

        palette = "catppuccin_mocha";

        palettes = {
          catppuccin_mocha = {
            rosewater = "#f5e0dc";
            flamingo = "#f2cdcd";
            pink = "#f5c2e7";
            mauve = "#cba6f7";
            red = "#f38ba8";
            maroon = "#eba0ac";
            peach = "#fab387";
            yellow = "#f9e2af";
            green = "#a6e3a1";
            teal = "#94e2d5";
            sky = "#89dceb";
            sapphire = "#74c7ec";
            blue = "#89b4fa";
            lavender = "#b4befe";
            text = "#cdd6f4";
            subtext1 = "#bac2de";
            subtext0 = "#a6adc8";
            overlay2 = "#9399b2";
            overlay1 = "#7f849c";
            overlay0 = "#6c7086";
            surface2 = "#585b70";
            surface1 = "#45475a";
            surface0 = "#313244";
            base = "#1e1e2e";
            mantle = "#181825";
            crust = "#11111b";
          };
        };

        os = {
          disabled = false;
          style = "fg:surface1 bg:red";
          symbols = {
            Windows = "󰍲";
            Ubuntu = "󰕈";
            SUSE = "";
            Raspbian = "󰐿";
            Mint = "󰣭";
            Macos = "󰀵";
            Manjaro = "";
            Linux = "󰌽";
            Gentoo = "󰣨";
            Fedora = "󰣛";
            Alpine = "";
            Amazon = "";
            Android = "";
            Arch = "󰣇";
            Artix = "󰣇";
            CentOS = "";
            Debian = "󰣚";
            Redhat = "󱄛";
            RedHatEnterprise = "󱄛";
            NixOS = "";
          };
        };

        username = {
          show_always = true;
          style_user = "bold fg:surface1 bg:red";
          style_root = "bold fg:surface1 bg:red";
          format = "[ $user]($style)";
        };

        hostname = {
          ssh_only = true;
          style = "bold fg:surface1 bg:red";
          format = "[$ssh_symbol$hostname]($style)";
        };

        nix_shell = {
          style = "bold fg:surface1 bg:red";
          impure_msg = "[● ](fg:yellow bg:red)";
          pure_msg = "[● ](fg:green bg:red)";
          format = "$state[$name]($style)";
        };

        directory = {
          style = "bold bg:peach fg:surface1";
          format = "[ $path]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
        };

        directory.substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };

        git_branch = {
          symbol = "";
          style = "bg:yellow";
          format = "[[ $symbol[ $branch](bold fg:surface1 bg:yellow)](fg:surface1 bg:yellow)]($style)";
        };

        git_status = {
          style = "bg:yellow";
          format = "[[ ($all_status$ahead_behind)](bold fg:surface1 bg:yellow)]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        c = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        rust = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        golang = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        php = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        java = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        kotlin = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        haskell = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        python = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol([ $version](bold fg:surface1 bg:green))](fg:surface1 bg:green)]($style)";
        };

        docker_context = {
          symbol = "";
          style = "bg:sapphire";
          format = "[[ $symbol([ $context](bold fg:surface1 bg:sapphire))](fg:surface1 bg:sapphire)]($style)";
        };

        conda = {
          style = "bg:sapphire";
          format = "[[ $symbol([ $environment](bold fg:surface1 bg:sapphire))](fg:#surface1 bg:sapphire)]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:lavender";
          format = "[[  $time](bold fg:surface1 bg:lavender)]($style)";
        };

        line_break = {
          disabled = false;
        };

        character = {
          disabled = false;
          success_symbol = "[](bold fg:green)";
          error_symbol = "[](bold fg:red)";
          vimcmd_symbol = "[](bold fg:green)";
          vimcmd_replace_one_symbol = "[](bold fg:blue)";
          vimcmd_replace_symbol = "[](bold fg:blue)";
          vimcmd_visual_symbol = "[](bold fg:yellow)";
        };
      };
    };
  };
}
