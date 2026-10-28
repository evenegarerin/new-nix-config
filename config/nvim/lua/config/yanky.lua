require("yanky").setup {
  preserve_cursor_position = {
    enabled = false,
  },
  highlight = {
    on_put = true,
    on_yank = false,
    timer = 300,
  },
}

-- NOTE: the target maps these in { "n", "x" }. Visual `p` is already
-- `"_c<Esc>p` from mappings.lua (Stage 1) -- paste over a selection without
-- clobbering the unnamed register -- and yanky loads later, so it would
-- silently take that over. Normal mode only.
vim.keymap.set("n", "p", "<Plug>(YankyPutAfter)")
vim.keymap.set("n", "P", "<Plug>(YankyPutBefore)")

-- cycle through the yank history, only work after paste
vim.keymap.set("n", "[y", "<Plug>(YankyPreviousEntry)")
vim.keymap.set("n", "]y", "<Plug>(YankyNextEntry)")
