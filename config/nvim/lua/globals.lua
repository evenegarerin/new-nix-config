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
-- netrw: replaced by nvim-tree in Stage 10. Disabling it now means `:Ex` and
-- opening a directory give you an empty buffer until then -- that is expected.
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

-- NOTE: nvim.bak also sets `loaded_matchit` and `loaded_matchparen` here,
-- because it replaces them with vim-matchup. Only add those two lines in
-- Stage 6 when vim-matchup is actually installed -- setting them now just
-- removes % matching and bracket highlighting with nothing taking over.

-- control how to show health check window
vim.g.health = { style = nil }
