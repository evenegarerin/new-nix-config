-- Merge of the previous config's options and the plugin-independent subset of
-- ../../nvim.bak/lua/options.lua. Lines marked [bak] come from the target,
-- lines marked [old] are carried over from the config that was in use before.
local utils = require("utils")

local fn = vim.fn
local symbol_icon = require("symbol_icon")
local opt = vim.opt
local o = vim.o

------------------------------------------------------------------------
--                            windows                                 --
------------------------------------------------------------------------
opt.splitbelow = true -- [bak] new horizontal splits go below
opt.splitright = true -- [bak] new vertical splits go right
opt.splitkeep = "screen" -- [bak] avoid flicker when splitting horizontally

------------------------------------------------------------------------
--                        timing / responsiveness                     --
------------------------------------------------------------------------
-- [old] 200ms. The target uses 500, which is friendlier once which-key is in
-- (Stage 8) because it gives you time to read the popup.
opt.timeoutlen = 400 -- enough to read the which-key popup (Stage 8); [bak] uses 500
opt.updatetime = 500 -- [bak] drives CursorHold, used by diagnostics + auto-read

------------------------------------------------------------------------
--                         files and backups                          --
------------------------------------------------------------------------
opt.swapfile = false -- [old] + [bak]
opt.undofile = true -- [bak] persistent undo across sessions
opt.autoread = true -- [bak] reload when changed outside nvim
opt.confirm = true -- [bak] ask instead of failing on unsaved changes

-- [bak] Ignore build artefacts and binaries during cmdline globbing.
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

-- [bak] Keep backups out of the project tree.
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
opt.tabstop = 2 -- [bak]
opt.softtabstop = 2 -- [bak]
opt.shiftwidth = 2 -- [bak]
opt.expandtab = true -- [bak]
opt.shiftround = true -- [bak] round indent to a multiple of shiftwidth
opt.smartindent = true -- [old]

------------------------------------------------------------------------
--                       line numbers and cursor                      --
------------------------------------------------------------------------
opt.number = true -- [old] + [bak]
opt.relativenumber = true -- [old] + [bak]
opt.scrolloff = 5 -- [old] + [bak]
opt.sidescrolloff = 3 -- [old]
opt.startofline = false -- [bak] keep the column when jumping
opt.virtualedit = "block" -- [bak] useful for visual block editing

------------------------------------------------------------------------
--                             search                                 --
------------------------------------------------------------------------
opt.ignorecase = true -- [old] + [bak]
opt.smartcase = true -- [old] + [bak]
opt.incsearch = true -- [old]
opt.hlsearch = true -- [old]

-- [bak] Use ripgrep for :grep when available.
if utils.executable("rg") then
  opt.grepprg = "rg --vimgrep --no-heading --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

------------------------------------------------------------------------
--                            clipboard                               --
------------------------------------------------------------------------
-- [bak] Only append unnamedplus if a clipboard provider actually exists,
-- otherwise every yank is slow and prints a provider warning.
if fn["provider#clipboard#Executable"]() ~= "" then
  opt.clipboard:append("unnamedplus")
end

------------------------------------------------------------------------
--                            appearance                              --
------------------------------------------------------------------------
opt.termguicolors = true -- [old] + [bak]
opt.showmode = false -- [bak] lualine's lualine_a shows the mode instead
opt.ruler = false -- [bak]
opt.showcmdloc = "statusline" -- [bak]
opt.wrap = false -- [bak]
opt.linebreak = true -- [bak] break at word boundaries when wrap is on
opt.showbreak = "|-> " -- [bak] marker for soft-wrapped lines
opt.signcolumn = "yes:1" -- [bak] always reserve one sign column
opt.colorcolumn = "100" -- [bak]
opt.synmaxcol = 250 -- [bak] stop highlighting very long lines

-- [bak] Fold chars, window separators, end-of-buffer and message separator.
opt.fillchars = symbol_icon.fillchars

-- Show tabs and trailing whitespace. [bak] glyphs, except `trail` which stays
-- the ° from the previous config -- the target does not set `trail` at all.
opt.list = true
opt.listchars = {
  tab = "→ ",
  trail = "°",
  extends = "❯",
  precedes = "❮",
  nbsp = "␣",
}

-- [bak] Cursor shape/colour per mode. The Cursor/Cursor2 highlight groups it
-- refers to are defined by the ColorScheme autocmd in Stage 1.
opt.guicursor =
  "n-v:block-Cursor/lCursor,i-c-ci-ve:ver50-blinkwait50-blinkoff100-blinkon175-Cursor2/lCursor2,r-cr:hor20,o:hor20"

opt.mouse = "n" -- [bak] mouse in normal mode only
opt.mousemodel = "popup"
opt.mousescroll = { "ver:1", "hor:0" }

opt.visualbell = true -- [bak]
opt.errorbells = false -- [bak]
opt.history = 500 -- [bak]

-- [bak] Floating window + popup menu look. `winborder`/`pumborder` are 0.11+.
opt.pumheight = 10
opt.pumblend = 5
opt.pumborder = "single"
opt.winblend = 0
opt.winborder = "single"

------------------------------------------------------------------------
--                   completion and messages                          --
------------------------------------------------------------------------
opt.completeopt:append("menuone") -- [bak] show menu even for a single match
opt.completeopt:remove("preview") -- [bak]
opt.shortmess:append("cS") -- [bak] silence completion + search-count messages
opt.messagesopt = "hit-enter,history:500" -- [bak]

------------------------------------------------------------------------
--                              misc                                  --
------------------------------------------------------------------------
-- [bak] Extra pairs for % and matching-bracket highlighting.
opt.matchpairs:append { "<:>" }

opt.spelllang = { "en" } -- [bak] (target also adds "cjk")
opt.spellsuggest:append("9")

opt.tildeop = true -- [bak] make ~ an operator, so it takes a motion
opt.isfname:remove { "=", "," } -- [bak]

-- [bak] diff behaviour: side-by-side, histogram algorithm, char-level inline.
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

-- NOTE: the target also sets `title`/`titlestring` via utils.get_titlestr(),
-- and `autowrite`/`autowriteall`. Both arrive with their respective stages --
-- get_titlestr is part of the full utils.lua pulled in at Stage 1.
