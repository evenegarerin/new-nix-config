local glance = require("glance")

glance.setup {
  height = 25,
  border = {
    enable = true,
  },
}

-- NOTE: the target binds bare `<space>g*`. With <Space> as leader these land in
-- the same namespace as fugitive's maps; they do not collide. See README.md
-- section 4.
vim.keymap.set("n", "<leader>gd", "<cmd>Glance definitions<cr>", { desc = "Glance: definitions" })
vim.keymap.set("n", "<leader>gr", "<cmd>Glance references<cr>", { desc = "Glance: references" })
vim.keymap.set("n", "<leader>gi", "<cmd>Glance implementations<cr>", { desc = "Glance: implementations" })
