local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  ------------------------------------------------------------------------------
  -- Colorscheme
  ------------------------------------------------------------------------------

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  ------------------------------------------------------------------------------
  -- LSP
  ------------------------------------------------------------------------------

  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      -- required by lua/plugins/lsp.lua (was provided by nix on nixos)
      "folke/neodev.nvim",
    },
    config = function()
      require("plugins.lsp")
    end,
  },

  ------------------------------------------------------------------------------
  -- Nvim Tree
  ------------------------------------------------------------------------------

  {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("plugins.nvimtree")
  end,
},

  ------------------------------------------------------------------------------
  -- Lualine
  ------------------------------------------------------------------------------

  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("plugins.lualine")
    end,
  },

  ------------------------------------------------------------------------------
  -- Telescope
  ------------------------------------------------------------------------------

  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("plugins.telescope")
    end,
  },

  ------------------------------------------------------------------------------
  -- Completion
  ------------------------------------------------------------------------------

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      -- required by lua/plugins/cmp.lua (was provided by nix on nixos)
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("plugins.cmp")
    end,
  },

  ------------------------------------------------------------------------------
  -- Comment.nvim
  ------------------------------------------------------------------------------

  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
      require("Comment").setup()
    end,
  },

  ------------------------------------------------------------------------------
  -- Symbols Outline
  ------------------------------------------------------------------------------

  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    config = function()
      require("symbols-outline").setup()
    end,
  },

}, {

  ------------------------------------------------------------------------------
  -- lazy.nvim settings
  ------------------------------------------------------------------------------

  install = {
    -- on arch the plugins are not provided by nix, so let lazy install them
    missing = true,
  },

  checker = {
    enabled = false,
  },

  change_detection = {
    enabled = false,
  },

  rocks = {
    enabled = false,
  },

  pkg = {
    enabled = false,
  },

  performance = {
    cache = {
      enabled = true,
    },
  },

})