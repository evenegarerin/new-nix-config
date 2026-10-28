-- Every nerd-font glyph used anywhere in the config, in one table: change an
-- icon here and it updates at every use site. Taken whole from
-- ../nvim.bak/lua/symbol_icon.lua (it has no dependencies).
--
-- A Stage 1 file, pulled forward because lualine reads from it throughout.
-- Stage 1 also wires `fillchars`/`indent`/`tabline` below into options.lua and
-- the plugins that use them; right now only the lualine-facing keys are live.

local M = {}

M.lsp = {
  icon = "",
  not_exist = "🚫",
}

M.git = {
  branch = "",
  diff = {
    added = "+",
    modified = "~",
    removed = "-",
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "│" },
  },
  commit = {
    ahead = "↑",
    behind = "↓",
  },
}

M.file = {
  readonly = "󰈡",
}

M.diagnostic = {
  error = "🆇",
  warn = "⚠️",
  info = "ℹ️",
  hint = "",
}

M.IME = {
  chinese = "[CN]",
}

M.python = ""

M.fileformat = {
  unix = "", -- e712
  dos = "", -- e70f
  mac = "", -- e711
}

M.statusline = {
  section_separators = {
    left = "",
    right = "",
  },
  component_separators = {
    left = "\\",
    right = "/",
  },
}

M.fillchars = {
  fold = " ",
  foldsep = " ",
  foldopen = "",
  foldclose = "",
  vert = "│",
  eob = " ",
  msgsep = "‾",
  diff = "╱",
}

M.indent = "▏"

M.tabline = {
  buffer_close = "",
  buffer_modified = "●",
  close = "",
  left_trunc_marker = "",
  right_trunc_marker = "",
}

M.fold_indicator = "󰁂"

return M
