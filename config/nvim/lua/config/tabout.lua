--- Step the cursor over an auto-paired closing delimiter in insert mode.
--- Wired into blink.cmp's <Tab> keymap list (see config/blink-cmp.lua), so it only
local M = {}

--- Characters nvim-autopairs closes with, plus `>` for tags/generics.
local closers = {
  [")"] = true,
  ["]"] = true,
  ["}"] = true,
  ['"'] = true,
  ["'"] = true,
  ["`"] = true,
  [">"] = true,
}

function M.forward()
  if vim.fn.mode() ~= "i" then
    return false
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- In insert mode `col` is the byte count before the cursor, so the character
  -- under/after it is at col + 1 (1-based sub). End of line yields "".
  if not closers[line:sub(col + 1, col + 1)] then
    return false
  end

  return vim.keycode("<C-g>U<Right>")
end

return M
