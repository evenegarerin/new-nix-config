local api = require("nvim-tree.api")

require("nvim-tree").setup {
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    api.config.mappings.default_on_attach(bufnr)

    -- free `f` so the global hop mapping reaches the tree
    vim.keymap.del("n", "f", { buffer = bufnr })
    vim.keymap.set("n", "<C-f>", api.live_filter.start,
      { buffer = bufnr, desc = "nvim-tree: live filter" })
  end,

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
}

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>ee", api.tree.toggle, "nvim-tree: toggle")
map("<leader>ef", function()
  if api.tree.is_tree_buf() then
      vim.cmd.wincmd("p")
  else
    api.tree.focus()
  end
end, "nvim-tree: toggle focus")
map("<leader>eg", api.tree.change_root_to_node, "nvim-tree: cd to node")
map("<leader>es", function()
  api.tree.find_file { open = true, focus = true, update_root = true }
end, "nvim-tree: reveal current file")
map("<leader>ec", api.tree.collapse_all, "nvim-tree: collapse all")