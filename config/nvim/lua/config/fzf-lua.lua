require("fzf-lua").setup {
  defaults = {
    file_icons = "mini",
  },
  winopts = {
    row = 0.5,
    height = 0.7,
  },
  files = {
    previewer = false,
    git_icons = true,
    no_ignore = false,
  },
  grep = {
    RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
  },
  buffers = {
    fzf_opts = { ["--header-lines"] = 0 },
  },
}

vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Fuzzy find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua live_grep_native<cr>", { desc = "Fuzzy grep files" })
vim.keymap.set(
  "n",
  "<leader>fh",
  "<cmd>FzfLua helptags<cr>",
  { desc = "Fuzzy grep tags in help files" }
)
vim.keymap.set(
  "n",
  "<leader>ft",
  "<cmd>FzfLua lsp_document_symbols<cr>",
  { desc = "Fuzzy search buffer tags" }
)
vim.keymap.set(
  "n",
  "<leader>fb",
  "<cmd>FzfLua buffers<cr>",
  { desc = "Fuzzy search opened buffers" }
)
vim.keymap.set(
  "n",
  "<leader>fr",
  "<cmd>FzfLua oldfiles<cr>",
  { desc = "Fuzzy search opened files history" }
)

vim.keymap.set(
  "n",
  "<leader>gbl",
  "<cmd>FzfLua git_branches<cr>",
  { desc = "Fuzzy search git branches" }
)
