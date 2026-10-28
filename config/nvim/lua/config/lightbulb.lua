---@diagnostic disable: missing-fields
require("nvim-lightbulb").setup {
  autocmd = {
    enabled = true,
    updatetime = -1,
  },
  ---@diagnostic disable-next-line: unused-local
  filter = function(client_name, result)
    local ignored_kinds = { "source.fixAll.ruff", "source.organizeImports.ruff" }

    if vim.tbl_contains(ignored_kinds, result.kind) then
      return false
    end

    return true
  end,
}
