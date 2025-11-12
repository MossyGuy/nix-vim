{
  description = "Neovim with lazy.nvim, Bamboo, C# and Java support as a Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    neovim-nightly.url = "github:neovim/neovim";
  };

  outputs = { self, nixpkgs, neovim-nightly }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      neovim-config = pkgs.writeText "init.lua" ''
        -- Bootstrap lazy.nvim plugin manager
        vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site/pack/lazy/start/lazy.nvim")

        require("lazy").setup({
          {
            'ribru17/bamboo.nvim',
            lazy = false,
            priority = 1000,
            config = function()
              require('bamboo').setup({})
              require('bamboo').load()
            end,
          },

          -- LSP and completion
          'neovim/nvim-lspconfig',
          'hrsh7th/nvim-cmp',
          'hrsh7th/cmp-nvim-lsp',
          'L3MON4D3/LuaSnip',
          'saadparwaiz1/cmp_luasnip',

          -- C# LSP requires omnisharp executable installed by nixpkgs package below
          {
            'OmniSharp/omnisharp-roslyn',
            -- no direct plugin config needed, LSP config below
          },

          -- Autoformatter conform.nvim
          {
            'mrjones2014/conform.nvim',
            config = function()
              require('conform').setup({
                format_on_save = true,
              })
            end,
          },

          -- Java LSP (jdtls)
          {
            'mfussenegger/nvim-jdtls',
            ft = { 'java' },
          },

          -- Statusline: lualine with Bamboo theme
          {
            'nvim-lualine/lualine.nvim',
            config = function()
              require('lualine').setup({
                options = {
                  theme = 'bamboo',
                  globalstatus = true,
                  section_separators = '',
                  component_separators = ''
                },
              })
            end,
          },
        })

        -- Neovim options
        vim.opt.laststatus = 3
        vim.opt.cmdheight = 0
        vim.g.dashboard_disable = 1
      '';
    in
    {
      packages.${system} = pkgs.neovim.overrideAttrs (old: {
        # Add lazy.nvim and language servers to the runtime dependencies so no manual install
        buildInputs = old.buildInputs ++ [
          pkgs.nodejs
          pkgs.git
          pkgs.omnisharp-roslyn
          pkgs.jdtls
          pkgs.ripgrep
          pkgs.fzf
          pkgs.luajit
        ];

        # Include our custom init.lua config
        dontPatchELF = true;
        installPhase = ''
          mkdir -p $out/share/nvim
          cp ${neovim-config} $out/share/nvim/init.lua
          cp -r ${pkgs.lazy-nvim}/share/nvim/site/* $out/share/nvim/site/
        '';
      });

      defaultPackage = self.packages.${system};

      # A shell environment with neovim available, for ease of use
      #devShells.${system} = pkgs.mkShell {
      #  buildInputs = [
      #    self.packages.${system}
      #  ];
      #};
    };
}
