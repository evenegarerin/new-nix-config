-- NOTE: bare `<space>f` in the target; see §4. Shadows the global `<leader>lf`
-- for json buffers. :JSONFormat comes from plugin/command.lua (Stage 2).
vim.keymap.set({ "n", "v" }, "<leader>lf", ":JSONFormat<cr>", {
  desc = "format file",
  buffer = true,
  silent = true,
})
