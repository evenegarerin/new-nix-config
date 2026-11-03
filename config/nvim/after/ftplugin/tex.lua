-- Prose buffer, not a code buffer: the same treatment markdown.vim and
-- text.vim give their filetypes.
vim.opt_local.wrap = true
vim.opt_local.colorcolumn = ""

-- vimtex conceals \alpha, \ldots and friends; keep the line under the cursor
-- unconcealed so it stays editable.
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "c"

-- spelllang is already `en` (lua/options.lua); <F11> toggles this off for the
-- stretches where it gets in the way (lua/mappings.lua).
vim.opt_local.spell = true
