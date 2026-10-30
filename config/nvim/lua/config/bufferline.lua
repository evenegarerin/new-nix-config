local symbol_icon = require("symbol_icon")

require("bufferline").setup {
  options = {
    numbers = "none",
    close_command = "bdelete! %d",
    right_mouse_command = nil,
    left_mouse_command = "buffer %d",
    middle_mouse_command = nil,
    indicator = {
      icon = "▎",
      style = "icon",
    },
    buffer_close_icon = symbol_icon.tabline.buffer_close,
    modified_icon = symbol_icon.tabline.buffer_modified,
    close_icon = symbol_icon.tabline.close,
    left_trunc_marker = symbol_icon.tabline.left_trunc_marker,
    right_trunc_marker = symbol_icon.tabline.right_trunc_marker,
    max_name_length = 18,
    max_prefix_length = 15,
    tab_size = 10,
    diagnostics = false,
    custom_filter = function(bufnr)
      local exclude_ft = { "qf", "git" }
      local cur_ft = vim.bo[bufnr].filetype
      local should_filter = vim.tbl_contains(exclude_ft, cur_ft)

      if should_filter then
        return false
      end

      return true
    end,
    show_buffer_icons = false,
    show_buffer_close_icons = true,
    show_close_icon = true,
    show_tab_indicators = true,
    persist_buffer_sort = true,
    separator_style = "bar",
    enforce_regular_tabs = false,
    always_show_bufferline = true,
    sort_by = "id",
  },
}

-- Move along the tabline as it is drawn
vim.keymap.set("n", "<leader>bh", "<cmd>BufferLineCyclePrev<cr>", {
  silent = true,
  desc = "bufferline: focus buffer to the left",
})

vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineCycleNext<cr>", {
  silent = true,
  desc = "bufferline: focus buffer to the right",
})

vim.keymap.set("n", "<leader>bx", function()
  -- `update` writes only when modified, and fails with E32 on a buffer that has no file name -- so only reach for it when there is something it can write.
  if vim.bo.modified and vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
    local ok, err = pcall(vim.cmd.update)

    -- A readonly file or a bad path must not end with the buffer closed and the changes gone.
    if not ok then
      vim.notify(tostring(err), vim.log.levels.ERROR, { title = "nvim-config" })
      return
    end
  end

  Snacks.bufdelete()
end, { desc = "bufferline: save and close buffer" })

