{
  pkgs,
  ...
}: {
  config = {
    home.packages = with pkgs; [
      ripgrep
      gcc
    ];

    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      colorschemes.catppuccin = {
        enable = true;
        settings.flavour = "mocha";
      };
      globals.mapleader = " ";
      keymaps = [
        {
          action.__raw = "vim.lsp.buf.hover";
          key = "<K>";
          mode = "n";
          options = {
            desc = "LSP Hover";
          };
        }
        {
          action.__raw = "vim.lsp.buf.definition";
          key = "<gd>";
          mode = "n";
          options = {
            desc = "LSP Go To Definition";
          };
        }
        {
          action.__raw = "vim.lsp.buf.code_action";
          key = "<leader>ca";
          mode = ["n" "v"];
          options = {
            desc = "LSP Code Actions";
          };
        }
        {
          action.__raw = "vim.lsp.buf.format";
          key = "<leader>gf";
          mode = "n";
          options = {
            desc = "LSP Format";
          };
        }
      ];

      opts = {
        expandtab = true;
        tabstop = 2;
        softtabstop = 2;
        shiftwidth = 2;
      };
      plugins = {

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            expand = ''
              function(args)
                require('luasnip').lsp_expand(args.body)
              end
            '';
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-e>" = "cmp.mapping.close()";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            };
            sources = [
              {name = "nvim_lsp";}
              {name = "luasnip";}
              {name = "path";}
              {name = "buffer";}
            ];
            window = {
              completion.border = [
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
              ];
              documentation.border = [
                ""
                ""
                ""
                ""
                ""
                ""
                ""
                ""
              ];
            };
          };
        };

        cmp_luasnip.enable = true;

        friendly-snippets.enable = true;

        lsp = {
          enable = true;
          inlayHints = true;
          servers = {
            lua_ls.enable = true;
            nixd = {
              enable = true;
              settings.nixpkgs.expr = "import (builtins.getFlake \"/home/1000/aviary\").inputs.nixpkgs { }";
            };
            ts_ls.enable = true;
          };
        };

        lualine = {
          enable = true;
          settings.options.theme = "catppuccin";
        };

        luasnip = {
          enable = true;
          fromVscode = [{}];
        };

        neo-tree.enable = true;

        none-ls = {
          enable = true;
          sources.formatting = {
            alejandra.enable = true;
            stylua.enable = true;
          };
        };

        telescope = {
          enable = true;
          extensions.ui-select.enable = true;
          keymaps = {
            "<C-p>" = {
              action = "find_files";
              mode = "n";
              options = {
                desc = "Telescope Files";
              };
            };
            "<leader>fg" = {
              action = "live_grep";
              mode = "n";
              options = {
                desc = "Telescope Live Grep";
              };
            };
          };
        };

        treesitter = {
          enable = true;
          settings = {
            auto_install = false;
            ensure_installed = "all";
            highlight = {
              additional_vim_regex_highlighting = true;
              custom_captures = {};
              enable = true;
            };
            indent.enable = true;
            parser_install_dir = {
              __raw = "vim.fs.joinpath(vim.fn.stdpath('data'), 'treesitter')";
            };
            sync_install = false;
          };
        };

        web-devicons.enable = true;
      };
    };

    #home.packages = [
    #  (lib.hiPrio (pkgs.runCommand "nvim.desktop-hide" { } ''
    #    mkdir -p "$out/share/applications"
    #    cat "${config.programs.nixvim.finalPackage}/share/applications/nvim.desktop" \
    #      > "$out/share/applications/nvim.desktop"
    #    echo "Hidden=1" >> "$out/share/applications/nvim.desktop"
    #  ''))
    #];
  };
}
