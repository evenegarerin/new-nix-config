require("nvim-tree").setup({
  diagnostics = {
    enable = true,

    show_on_dirs = true,
    show_on_open_dirs = true,

    icons = {
      hint = "󰌵",
      info = "󰋼",
      warning = "",
      error = "",
    },
  },
})