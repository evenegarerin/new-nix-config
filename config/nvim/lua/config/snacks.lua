require("snacks").setup {
  input = {
    enabled = true,
    win = {
      relative = "cursor",
      backdrop = true,
    },
  },

  picker = { enabled = true },
}

vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "lazygit" })

vim.keymap.set("n", "<leader>gG", function()
  Snacks.lazygit.log()
end, { desc = "lazygit: repo log" })

vim.keymap.set("n", "<leader>gh", function()
  Snacks.lazygit.log_file()
end, { desc = "lazygit: history of this file" })
