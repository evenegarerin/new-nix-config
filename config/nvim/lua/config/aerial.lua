require("aerial").setup {
  layout = {
    -- These control the width of the aerial window.
    -- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
    -- min_width and max_width can be a list of mixed types.
    -- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
    max_width = { 40, 0.2 },
    width = nil,
    min_width = 20,
  },
  -- optionally use on_attach to set keymaps when aerial has attached to a buffer
  on_attach = function(bufnr)
    -- Jump forwards/backwards with '{' and '}'
    vim.keymap.set("n", "[t", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    vim.keymap.set("n", "]t", "<cmd>AerialNext<CR>", { buffer = bufnr })
  end,
}
-- NOTE: the target binds a bare `<space>t`, which collides with <Space> as
-- leader. See README.md section 4.
vim.keymap.set("n", "<leader>to", "<cmd>AerialToggle!<CR>", { desc = "toggle symbol outline" })
