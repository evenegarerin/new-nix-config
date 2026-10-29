local utils = require("utils")

local fn = vim.fn
local symbol_icon = require("symbol_icon")
local opt = vim.opt
local o = vim.o

------------------------------------------------------------------------
--                            windows                                 --
------------------------------------------------------------------------
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

------------------------------------------------------------------------
--                        timing / responsiveness                     --
------------------------------------------------------------------------
opt.timeoutlen = 200
opt.updatetime = 500

------------------------------------------------------------------------
--                         files and backups                          --
------------------------------------------------------------------------
opt.swapfile = false
opt.undofile = true
opt.autoread = true
opt.confirm = true

opt.wildignore:append {
  "*.o",
  "*.obj",
  "*.dylib",
  "*.bin",
  "*.dll",
  "*.exe",
  "*/.git/*",
  "*/__pycache__/*",
  "*/build/**",
  "*/result/*",
  "*/elm-stuff/*",
  "*.jpg",
  "*.png",
  "*.jpeg",
  "*.gif",
  "*.ico",
  "*.pyc",
  "*.DS_Store",
}
opt.wildignorecase = true
opt.wildmode = "list:longest"

vim.g.backupdir = fn.stdpath("data") .. "/backup//"
-- nvim does not create backupdir itself; without this it silently falls back
-- to writing the backup next to the file (or skips it).
utils.may_create_dir(fn.stdpath("data") .. "/backup")
opt.backupdir = vim.g.backupdir
opt.backupskip = o.wildignore
opt.backup = true
opt.backupcopy = "yes"

opt.fileencoding = "utf-8"
opt.fileformats = { "unix", "dos" }

------------------------------------------------------------------------
--                          indentation                               --
------------------------------------------------------------------------
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.shiftround = true
opt.smartindent = true

------------------------------------------------------------------------
--                       line numbers and cursor                      --
------------------------------------------------------------------------
opt.number = true
opt.relativenumber = true
opt.scrolloff = 5
opt.sidescrolloff = 3
opt.startofline = false
opt.virtualedit = "block"

------------------------------------------------------------------------
--                             search                                 --
------------------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

if utils.executable("rg") then
  opt.grepprg = "rg --vimgrep --no-heading --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

------------------------------------------------------------------------
--                            clipboard                               --
------------------------------------------------------------------------
if fn["provider#clipboard#Executable"]() ~= "" then
  opt.clipboard:append("unnamedplus")
end

------------------------------------------------------------------------
--                            appearance                              --
------------------------------------------------------------------------
opt.termguicolors = true
opt.showmode = false
opt.ruler = false
opt.showcmdloc = "statusline"
opt.wrap = false
opt.linebreak = true
opt.showbreak = "|-> "
opt.signcolumn = "no"
opt.statuscolumn = "%{%v:lua.require'statuscolumn'.render()%}"
-- opt.colorcolumn = "100"
opt.synmaxcol = 250

opt.fillchars = symbol_icon.fillchars

opt.list = true
opt.listchars = {
  tab = "→ ",
  trail = "°",
  extends = "❯",
  precedes = "❮",
  nbsp = "␣",
}

opt.guicursor = "n-v:block-Cursor/lCursor,i-c-ci-ve:ver50-blinkwait50-blinkoff100-blinkon175-Cursor2/lCursor2,r-cr:hor20,o:hor20"

opt.mouse = "n"
opt.mousemodel = "popup"
opt.mousescroll = { "ver:1", "hor:0" }

opt.visualbell = true
opt.errorbells = false
opt.history = 500

opt.pumheight = 10
opt.pumblend = 5
opt.pumborder = "single"
opt.winblend = 0
opt.winborder = "single"

------------------------------------------------------------------------
--                   completion and messages                          --
------------------------------------------------------------------------
opt.completeopt:append("menuone")
opt.completeopt:remove("preview")
opt.shortmess:append("cS")
opt.messagesopt = "hit-enter,history:500"

------------------------------------------------------------------------
--                              misc                                  --
------------------------------------------------------------------------
opt.matchpairs:append { "<:>" }

opt.spelllang = { "en" }
opt.spellsuggest:append("9")

opt.tildeop = true
opt.isfname:remove { "=", "," }

opt.diffopt = {
  "vertical",
  "filler",
  "closeoff",
  "context:3",
  "internal",
  "indent-heuristic",
  "algorithm:histogram",
}
opt.diffopt:append("inline:char")
