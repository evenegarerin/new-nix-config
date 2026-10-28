require("nvim-treesitter-textobjects").setup {
  select = {
    lookahead = false,

    selection_modes = {
      ["@function.inner"] = "V", -- linewise
      ["@function.outer"] = "V", -- linewise
      ["@class.outer"] = "V", -- linewise
      ["@class.inner"] = "V", -- linewise
      ["@parameter.outer"] = "v", -- charwise
    },

    include_surrounding_whitespace = false,
  },
}

-- keymaps
vim.keymap.set({ "x", "o" }, "af", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "if", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ac", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ic", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "as", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
end)
