-- NOTE: Stage 1 remaps global `q` to a "use Q" reminder, which costs `q` in
-- help too. The target only restores it for man pages (after/ftplugin/man.lua);
-- this is the same buffer-local fix for help. The global mapping is untouched.
vim.keymap.set("n", "q", "<cmd>quit<CR>", {
  desc = "close help window",
  buffer = true,
  silent = true,
})

local win_width = vim.api.nvim_win_get_width(0)

-- do not change layout if the screen is not wide enough
if win_width < 200 then
  return
end

-- L means to put window to leftmost
vim.cmd.wincmd([[L]])
