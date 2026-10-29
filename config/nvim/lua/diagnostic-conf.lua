local symbol_icon = require("symbol_icon")
local diagnostic = vim.diagnostic
local api = vim.api

diagnostic.config {
  underline = true,
  virtual_text = true,
  update_in_insert = true,
  signs = {
    text = {
      [diagnostic.severity.ERROR] = symbol_icon.diagnostic.error,
      [diagnostic.severity.WARN] = symbol_icon.diagnostic.warn,
      [diagnostic.severity.INFO] = symbol_icon.diagnostic.info,
      [diagnostic.severity.HINT] = symbol_icon.diagnostic.hint,
    },
  },
  severity_sort = true,
  float = {
    source = true,
    header = "Diagnostics:",
    prefix = " ",
    border = "single",
    max_height = 10,
    max_width = 130,
    close_events = { "CursorMoved", "BufLeave", "WinLeave", "InsertEnter" },
  },
}

--- Diagnostics from one buffer into the quickfix list.
local set_qflist = function(buf_num, severity)
  local diagnostics = diagnostic.get(buf_num, { severity = severity })

  vim.fn.setqflist({}, " ", {
    title = "Diagnostics",
    items = diagnostic.toqflist(diagnostics),
  })

  vim.cmd([[copen]])
end

vim.keymap.set("n", "<leader>dw", diagnostic.setqflist, { desc = "window diagnostics to qf" })

vim.keymap.set("n", "<leader>db", function()
  set_qflist(0)
end, { desc = "buffer diagnostics to qf" })

api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  callback = function()
    if #vim.diagnostic.get(0) == 0 then
      return
    end

    if not vim.b.diagnostics_pos then
      vim.b.diagnostics_pos = { nil, nil }
    end

    local cursor_pos = api.nvim_win_get_cursor(0)

    if not vim.deep_equal(cursor_pos, vim.b.diagnostics_pos) then
      diagnostic.open_float {}
    end

    vim.b.diagnostics_pos = cursor_pos
  end,
})
