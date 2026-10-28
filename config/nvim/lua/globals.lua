local utils = require("utils")

------------------------------------------------------------------------
--                          custom variables                          --
------------------------------------------------------------------------
-- Used by plugin specs and platform-dependent config further down the line.
vim.g.is_win = (utils.has("win32") or utils.has("win64")) and true or false
vim.g.is_linux = (utils.has("unix") and (not utils.has("macunix"))) and true or false
vim.g.is_mac = utils.has("macunix") and true or false

vim.g.logging_level = vim.log.levels.INFO

------------------------------------------------------------------------
--                         builtin variables                          --
------------------------------------------------------------------------
-- NOTE: the target config uses "," as leader. We keep <Space>, which means
-- every `<space>X` mapping copied from nvim.bak has to be rewritten as a
-- two-key `<leader>` sequence. See the "Leader key" section in README.md.
vim.g.mapleader = " "

-- Disable language providers we do not use. Perl/Ruby/Node are never needed;
-- python3 is only required by ultisnips and iron.nvim, both of which we skip.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

vim.g.did_install_default_menus = 1 -- do not load menu

-- Enable highlighting for lua HERE doc inside vim script
vim.g.vimsyn_embed = "l"

-- Use English as main language
vim.cmd([[language en_US.UTF-8]])

------------------------------------------------------------------------
--                    disable builtin plugins                         --
------------------------------------------------------------------------
-- netrw: replaced by nvim-tree, which is loaded from lua/plugin_specs.lua.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.netrw_liststyle = 3

vim.g.loaded_2html_plugin = 1

-- plugins for peeking inside compressed files
vim.g.loaded_zipPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1

vim.g.loaded_tutor_mode_plugin = 1

-- Broken, see the upstream note in nvim.bak/lua/globals.lua
vim.g.loaded_sql_completion = 1

-- vim-matchup (Stage 6) replaces both of these: it provides % matching and
-- bracket highlighting, with offscreen-match popups and deferred highlighting.
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1

-- control how to show health check window
vim.g.health = { style = nil }
