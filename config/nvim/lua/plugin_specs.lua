-- lazy.nvim bootstrap + plugin specs.
-- Mirrors ../nvim.bak/lua/plugin_specs.lua; specs are added stage by stage,
-- see README.md. Currently: Stage 3 + the nvim-tree slice of Stage 10.

local plugin_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
local lazypath = vim.fs.joinpath(plugin_dir, "lazy.nvim")

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local plugin_specs = {
  -- NOTE: the target picks one of 25 colorschemes at random on every start, so it
  -- can mark them all `lazy = true`. With a single fixed scheme it has to be
  -- eagerly loaded with a high priority instead, or `ui.lua` runs before it exists.
  { "rebelot/kanagawa.nvim", priority = 1000 },

  -- nerd font icons. `mock_nvim_web_devicons` is a compatibility shim for plugins
  -- that only know nvim-web-devicons -- nvim-tree is one of them, which is why
  -- this is declared as its dependency: lazy.nvim runs a dependency's `config`
  -- before the dependent loads, so the mock is in place in time.
  {
    "nvim-mini/mini.icons",
    version = false,
    lazy = true,
    config = function()
      require("mini.icons").mock_nvim_web_devicons()
      require("mini.icons").tweak_lsp_kind()
    end,
  },

  ---------------------------------------------------------------------------
  -- Stage 13: optional extras
  ---------------------------------------------------------------------------

  -- Render #rrggbb / rgb() literals in their own colour. Relevant here: this
  -- repo carries several CSS files (firefox userChrome, swaync, walker,
  -- ulauncher) plus hex colours throughout the nvim config.
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    config = function()
      require("config.nvim-colorizer")
    end,
  },

  -- :Messages, :Scriptnames, :Verbose -- for when the config misbehaves
  { "tpope/vim-scriptease", cmd = { "Scriptnames", "Messages", "Verbose" } },

  -- :Obsess to record a session that keeps itself up to date
  { "tpope/vim-obsession", cmd = { "Obsess", "Obsession" } },

  ---------------------------------------------------------------------------
  -- Stage 12: filetype layer
  ---------------------------------------------------------------------------

  -- In-buffer markdown rendering: styled headings, bullets, code blocks, tables
  {
    "MeanderingProgrammer/render-markdown.nvim",
    main = "render-markdown",
    opts = {},
    ft = { "markdown" },
  },

  -- :Tabularize /| to align markdown tables on a separator
  { "godlygeek/tabular", cmd = { "Tabularize", "AddTabularPattern", "AddTabularPipeline" } },

  -- ^^ inserts a numbered footnote, @@ jumps back. after/ftplugin/markdown.vim
  -- has a guarded block wiring these up -- inert unless this plugin is present.
  { "vim-pandoc/vim-markdownfootnotes", ft = { "markdown" } },

  ---------------------------------------------------------------------------
  -- Stage 11: text objects and editing power. Mostly init-only plugins.
  ---------------------------------------------------------------------------

  -- ci, da( in[ -- arguments, and next/last variants of every pair
  { "wellle/targets.vim", event = "VeryLazy" },

  -- sa/sd/sr add, delete, replace surrounding pairs: `saiw"` quotes a word
  {
    "machakann/vim-sandwich",
    init = function()
      vim.cmd([[
        " s is the vim-sandwich prefix. Use cl instead of s for substitute.
        nmap s <Nop>
        omap s <Nop>
      ]])
    end,
    event = "VeryLazy",
  },

  -- Auto-close brackets and quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- gcc, gc{motion}. Replaces Comment.nvim from the pre-rebuild config.
  {
    "tpope/vim-commentary",
    keys = {
      { "gc", mode = "n" },
      { "gc", mode = "v" },
    },
  },

  -- Makes `.` repeat the plugin maps above
  { "tpope/vim-repeat", event = "VeryLazy" },

  -- :Rename, :Delete, :Move
  { "tpope/vim-eunuch", cmd = { "Rename", "Delete", "Move", "Chmod", "Mkdir" } },

  -- Live preview for :norm, :g and :s
  {
    "smjonas/live-command.nvim",
    event = "CmdlineEnter",
    config = function()
      require("config.live-command")
    end,
  },

  -- ga -> what character is this
  { "chrisbra/unicode.vim", cmd = { "UnicodeName", "UnicodeTable", "UnicodeSearch" }, keys = { "ga" } },

  -- Highlights trailing space, and provides :StripTrailingWhitespace, which is
  -- what unblocks <leader><space> parked in mappings.lua since Stage 1.
  { "nvim-zh/whitespace.nvim", event = "VeryLazy" },

  -- jk to leave insert mode
  {
    "nvim-zh/better-escape.vim",
    init = function()
      vim.cmd([[let g:better_escape_interval = 200]])
    end,
    event = { "InsertEnter" },
  },

  -- Underlines URLs. Also what text_obj#URL() (Stage 2) prefers for its
  -- pattern -- without it `iu` falls back to an expand('<cfile>') heuristic.
  { "itchyny/vim-highlighturl", event = "VeryLazy" },

  -- Jump anywhere on screen. Binds `f` -- this replaces vim's within-line
  -- f{char}; F, t and T are untouched. `;` as f-repeat was already given up in
  -- Stage 1, where it became `:`.
  {
    "smoka7/hop.nvim",
    keys = { { "f", mode = { "n", "x", "o" } } },
    config = function()
      require("config.nvim_hop")
    end,
  },

  -- Search match counter: "3/17" next to the match. Needs `shortmess+=S`,
  -- which options.lua already sets, or nvim prints its own count over it.
  {
    "kevinhwang91/nvim-hlslens",
    branch = "main",
    keys = { "*", "#", "n", "N" },
    config = function()
      require("config.hlslens")
    end,
  },

  -- Quickfix: preview pane for the list.
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    config = function()
      require("config.bqf")
    end,
  },
  -- Peek definitions/references in a float: <leader>gd / gr / gi
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    keys = { "<leader>gd", "<leader>gr", "<leader>gi" },
    config = function()
      require("config.glance")
    end,
  },

  -- Sign in the gutter when a code action is available.
  {
    "kosayoda/nvim-lightbulb",
    event = "LspAttach",
    config = function()
      require("config.lightbulb")
    end,
  },

  -- Highlight other occurrences of the word under the cursor.
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("config.vim-illuminate")
    end,
  },

  -- Git change signs in the sign column, plus hunk navigation and staging.
  -- Detects a repo itself, so it does not need the InGitRepo event.
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    version = "*",
    config = function()
      require("config.gitsigns")
    end,
  },

  -- Permalinks to the current line on the forge.
  --
  -- NOTE: `User InGitRepo` is a custom event -- it only fires because
  -- `utils.inside_git_repo()` runs from the `git_repo_check` autocmd in
  -- custom-autocmd.lua (Stage 2). This is now its only consumer; if
  -- `<leader>gl` does nothing, check that first -- `:Lazy` will show this as
  -- never-loaded.
  --
  -- NOTE: gitlinker requires plenary. The target gets it only because neogit
  -- lists it as a dependency; neogit is skipped here, so it is declared.
  {
    "ruifm/gitlinker.nvim",
    event = "User InGitRepo",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("config.git-linker")
    end,
  },

  { "nvim-lua/plenary.nvim", lazy = true },

  -- NOTE: the target also ships NeogitOrg/neogit (a magit-style UI) alongside
  -- fugitive, and rbong/vim-flog. Both are skipped, and fugitive itself has
  -- since been removed -- lazygit covers that ground, launched from snacks
  -- (`<leader>gg`, see config/snacks.lua).

  -- Buffer tabline. The target guards this with `cond = firenvim_not_active`;
  -- firenvim is not installed, so the guard is dropped.
  {
    "akinsho/bufferline.nvim",
    event = { "BufEnter" },
    config = function()
      require("config.bufferline")
    end,
  },

  -- Popup listing what follows a prefix. This is the payoff for every
  -- `desc = "..."` in the mappings, and its usefulness scales with `timeoutlen`
  -- (raised to 400 in options.lua for exactly this).
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("config.which-key")
    end,
  },

  -- Notification popups. Takes over vim.notify globally.
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      require("config.nvim-notify")
    end,
  },

  -- Breadcrumb winbar; needs no config, driven by LSP/treesitter.
  -- NOTE: the target uses `event = "VeryLazy"`. dropbar self-initialises from a
  -- `once` FileType autocmd in its own plugin/dropbar.lua, so any lazy trigger
  -- that fires *after* the first buffer's FileType leaves that buffer with no
  -- winbar until you switch away and back. Loading it eagerly sources that
  -- plugin file before any filetype is set.
  {
    "Bekaboo/dropbar.nvim",
    lazy = false,
  },

  -- Vertical line marking the current indent scope.
  {
    "nvim-mini/mini.indentscope",
    version = false,
    event = "VeryLazy",
    config = function()
      local mini_indent = require("mini.indentscope")
      mini_indent.setup {
        draw = {
          -- instant, no sliding animation
          animation = mini_indent.gen_animation.none(),
        },
        symbol = require("symbol_icon").indent,
      }
    end,
  },

  -- Fuzzy finder. Replaces telescope + telescope-fzf-native from the pre-rebuild
  -- config. fzf, rg and fd are all already on PATH.
  --
  -- NOTE: the target keeps telescope installed alongside this
  -- (plugin_specs.lua:136-142, `cmd = "Telescope"`) purely for telescope-symbols.
  -- Not worth a second finder; both are skipped.
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    dependencies = { "nvim-mini/mini.icons" }, -- `file_icons = "mini"` below
    config = function()
      require("config.fzf-lua")
    end,
  },

  -- Three of its ~20 modules are used: `input` and `picker`, which upgrade
  -- vim.ui.input and vim.ui.select (what makes LSP rename and code-action
  -- pickers look right), and `lazygit`, which needs no `enabled` flag because
  -- it is on-demand rather than event-driven. The rest stay off.
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("config.snacks")
    end,
  },

  -- Treesitter, `main` branch (the rewritten API -- there is no
  -- `require("nvim-treesitter.configs").setup{}` here; do not mix main-branch
  -- code with master-branch tutorials).
  --
  -- Parsers and queries come from nix (see home.nix), so nothing is compiled at
  -- runtime and `build = ":TSUpdate"` is deliberately absent. The plugin is
  -- still needed for plugin/query_predicates.lua, which the bundled queries use,
  -- and as the dependency the textobjects/treesj plugins expect.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    config = function()
      require("config.treesitter")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- NOTE: the target also sets `vim.g.no_plugin_maps = true` here
    -- (plugin_specs.lua:98). Despite sitting in this plugin's spec it disables
    -- *every* builtin ftplugin mapping for *every* filetype -- `gO` in help,
    -- `[[`/`]]` section motions, and so on. Nothing in the af/if/ac/ic/as set
    -- below collides with those, so it is left unset.
    config = function()
      require("config.treesitter-textobjects")
    end,
  },

  -- gS: split/join a node across lines
  {
    "Wansmer/treesj",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("config.treesj")
    end,
  },

  -- Modern matchit: % matching, and the reason globals.lua disables
  -- matchit/matchparen.
  {
    "andymass/vim-matchup",
    init = function()
      vim.cmd([[
        " Improve performance
        let g:matchup_matchparen_deferred = 1
        let g:matchup_matchparen_timeout = 100
        let g:matchup_matchparen_insert_timeout = 30

        " Enhanced matching with matchup plugin
        let g:matchup_override_vimtex = 1

        " Whether to enable matching inside comment or string
        let g:matchup_delim_noskips = 0

        " Show offscreen match pair in popup window
        let g:matchup_matchparen_offscreen = {'method': 'popup'}
      ]])
    end,
    event = "BufRead",
  },

  -- LSP. nvim-lspconfig supplies each server's default cmd/root_markers/
  -- filetypes; the actual enabling happens in lua/lsp_conf.lua.
  { "neovim/nvim-lspconfig" },

  -- Lua LS tuned for editing nvim config. Replaces neodev (deprecated) from the
  -- pre-rebuild config, and makes the manual VIMRUNTIME workspace.library
  -- setting unnecessary.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "nvim-lspconfig", words = { "lspconfig" } },
      },
    },
  },

  -- LSP progress spinner
  {
    "j-hui/fidget.nvim",
    event = "BufRead",
    config = function()
      require("config.fidget-nvim")
    end,
  },

  -- Completion. Replaces nvim-cmp + LuaSnip + cmp_luasnip + cmp-nvim-lsp from
  -- the pre-rebuild config: blink has an LSP source, a Rust fuzzy matcher and
  -- its own snippet engine, so four plugins collapse into one.
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "xzbdmw/colorful-menu.nvim",
      "archie-judd/blink-cmp-words",
    },
    -- a release tag, so the prebuilt Rust fuzzy matcher is downloaded
    version = "1.*",
    config = function()
      require("config.blink-cmp")
    end,
    opts_extend = { "sources.default" },
  },

  -- syntax-highlighted completion item labels; wired into blink's
  -- completion.menu.draw in config/blink-cmp.lua
  {
    "xzbdmw/colorful-menu.nvim",
    lazy = true,
    config = function()
      require("config.colorful_menu")
    end,
  },

  -- thesaurus/dictionary completion sources, used for text and markdown
  { "archie-judd/blink-cmp-words", lazy = true },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    -- NOTE: nui.nvim is deliberately NOT a dependency here -- lazy.nvim loads a
    -- plugin's dependencies eagerly along with it, and only the branch-menu
    -- click handler needs nui. Its `require("nui.menu")` trips lazy's module
    -- loader on demand instead.
    dependencies = { "nvim-mini/mini.icons" },
    config = function()
      require("config.lualine")
    end,
  },

  -- UI component library. Only the branch-checkout menu in config/lualine.lua
  -- uses it so far; Stage 4's `:LspAttached` popup wants it too.
  { "MunifTanjim/nui.nvim", lazy = true },

  -- file explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    -- NOTE: the VimEnter autocmd that opens the tree on a directory argument
    -- lives in lua/custom-autocmd.lua. It cannot live in config/nvim-tree.lua,
    -- which only runs on VeryLazy -- after VimEnter has already fired.
    config = function()
      require("config.nvim-tree")
    end,
  },
}

require("lazy").setup {
  spec = plugin_specs,
  concurrency = 5,
  ui = {
    border = "rounded",
    title = "Plugin Manager",
    title_pos = "center",
  },
  rocks = {
    -- hererocks pulls in a whole Lua toolchain otherwise
    enabled = false,
    hererocks = false,
  },
}

-- Short names for the common plugin manager commands. Type `:`, then the alias,
-- then <space>, and it expands. `utils#Cabbrev` comes from autoload/utils.vim.
vim.fn["utils#Cabbrev"]("pi", "Lazy install")
vim.fn["utils#Cabbrev"]("pud", "Lazy update")
vim.fn["utils#Cabbrev"]("pc", "Lazy clean")
vim.fn["utils#Cabbrev"]("ps", "Lazy sync")
