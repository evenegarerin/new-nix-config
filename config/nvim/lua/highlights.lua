local errorColor = "#ff0000"
local warnColor = "#ffa600"
local infoColor = "#0000ff"
local hintColor = "#00ffb3"

vim.api.nvim_set_hl(0, "Comment", {
  fg = "#007c00",
  underline = true,
  bold = true,
})

vim.api.nvim_set_hl(0, "Normal", {
  bg = "none",
})

vim.api.nvim_set_hl(0, "NormalNC", {
  bg = "none",
})

vim.api.nvim_set_hl(0, "NvimTreeNormal", {
  bg = "none",
})

vim.api.nvim_set_hl(0, "NvimTreeNormalNC", {
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticError", {
  fg = errorColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", {
  fg = errorColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
  sp = errorColor,
  undercurl = true,
})

vim.api.nvim_set_hl(0, "DiagnosticWarn", {
  fg = warnColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", {
  fg = warnColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", {
  sp = warnColor,
  undercurl = true,
})

vim.api.nvim_set_hl(0, "DiagnosticInfo", {
  fg = infoColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", {
  fg = infoColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", {
  sp = infoColor,
  undercurl = true,
})

vim.api.nvim_set_hl(0, "DiagnosticHint", {
  fg = hintColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", {
  fg = hintColor,
  bg = "none",
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", {
  sp = hintColor,
  undercurl = true,
})

vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", {
  bg = "none",
  fg = "#a3a3a3",
})

vim.api.nvim_set_hl(0, "SignColumn", {
  bg = "none",
})