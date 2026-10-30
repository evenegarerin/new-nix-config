vim.keymap.set({ "n", "v" }, "<leader>lf", ":JSONFormat<cr>", {
  desc = "format file",
  buffer = true,
  silent = true,
})
