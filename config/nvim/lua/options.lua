vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 3

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.incsearch = true
vim.opt.hlsearch = true

vim.opt.list = true
vim.opt.listchars = {
  tab = " ",
  trail = "°",
}

vim.opt.smartindent = true

vim.opt.swapfile = false

vim.opt.termguicolors = true

vim.cmd.colorscheme("tokyonight-moon")

vim.opt.clipboard = "unnamedplus"

vim.opt.timeoutlen = 200
