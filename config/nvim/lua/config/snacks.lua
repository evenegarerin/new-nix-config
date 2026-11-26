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

vim.keymap.set("n", "<leader>t", function()
  local default_colors = {}
  for i = 0, 15 do
    default_colors["terminal_color_" .. i] = false
  end
  Snacks.terminal.toggle(nil, {
    win = {
      b = default_colors,
      position = "float",
      border = "rounded",
      keys = {
        hide_slash = { "<c-/>", "hide", mode = { "t", "n" } },
        hide_underscore = { "<c-_>", "hide", mode = { "t", "n" } },
      },
    },
  })
end, { desc = "toggle floating terminal" })
