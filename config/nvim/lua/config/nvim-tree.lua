local api = require("nvim-tree.api")

-- The target's setup is a bare `setup {}`; the diagnostics block comes from the
-- pre-rebuild config (git show 4dedfd2^:config/nvim/lua/plugins/nvimtree.lua).
-- It is inert until Stage 4 brings LSP, then it marks files with diagnostics.
require("nvim-tree").setup {
  diagnostics = {
    enable = true,

    show_on_dirs = true,
    show_on_open_dirs = true,

    icons = {
      hint = "󰌵",
      info = "󰋼",
      warning = "",
      error = "",
    },
  },
}

-- The target binds a bare `<space>s`; the pre-rebuild config used `<leader>e`
-- focus / `<leader>ee` toggle, where the one-key map only fires after
-- `timeoutlen` because it is a prefix of the other. See README.md section 4.
local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>ee", api.tree.toggle, "nvim-tree: toggle")
map("<leader>ef", api.tree.focus, "nvim-tree: focus")
map("<leader>ec", api.tree.change_root_to_node, "nvim-tree: cd to node")
