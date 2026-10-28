-- Disable inserting comment leader after hitting o/O/<Enter>
vim.opt_local.formatoptions:remove { "o", "r" }

vim.keymap.set("n", "<F9>", "<cmd>luafile %<CR>", {
  buffer = true,
  silent = true,
})
-- NOTE: the target binds a bare `<Space>f`, which collides with <Space> as
-- leader (§4). This shadows the global `<leader>lf` (vim.lsp.buf.format) for lua
-- buffers only -- stylua is the right formatter here, and lua_ls does not format
-- by default anyway.
--
-- `checktime` is added because stylua rewrites the file on disk behind nvim's
-- back; without it the buffer shows stale text until the auto_read autocmd
-- happens to fire.
vim.keymap.set("n", "<leader>lf", "<cmd>silent !stylua %<CR><cmd>checktime<CR>", {
  desc = "format file (stylua)",
  buffer = true,
  silent = true,
})
