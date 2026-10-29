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
vim.g.mapleader = " "

-- Disable language providers we do not use. Perl/Ruby/Node are never needed;
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

-- Broken, maybe
vim.g.loaded_sql_completion = 1

-- bracket highlighting, with offscreen-match popups and deferred highlighting.
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1

-- control how to show health check window
vim.g.health = { style = nil }
