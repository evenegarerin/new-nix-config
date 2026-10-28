require("treesj").setup {
  use_default_keymaps = false,
}

-- todo might want to change the keybind later
vim.keymap.set("n", "gS", require("treesj").toggle, { desc = "Toggle split join" })
