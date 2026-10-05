local map = vim.keymap.set

map("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")

map("i", "<A-j>", "<Esc>")

map(
  "n",
  "<leader>k",
  "<cmd>lua vim.fn.jobstart({'kitty', '--directory', vim.fn.getcwd()}, { detach = true })<CR>"
)

map("n", "<leader>w", "<cmd>w<CR>")

map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>")
map("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>")

map(
  "n",
  "<leader>c",
  '<cmd>lua require("nvim-tree.api").tree.change_root_to_node()<CR>'
)

map("n", "<leader>p", '"+p')