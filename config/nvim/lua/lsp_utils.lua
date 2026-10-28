local symbol_icon = require("symbol_icon")

local M = {}

M.get_default_capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- required by nvim-ufo (Stage 8)
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  return capabilities
end

--- Names of the LSP clients attached to the current buffer.
--- @return string[]
M.get_attached_lsp = function()
  local clients = vim.lsp.get_clients { bufnr = 0 }

  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end

  return client_names
end

--- Floating list of the attached servers. Backs `:LspAttached` and the
--- statusline LSP component's on_click.
--- @param size { width: integer, height: integer }
--- @param position { row: integer, col: integer }
M.show_lsp_menu = function(size, position)
  local Menu = require("nui.menu")
  local NuiLine = require("nui.line")

  --- @type nui_popup_options
  local popup_options = {
    relative = "win",
    position = {
      row = position.row,
      col = position.col,
    },
    size = {
      width = size.width,
      height = size.height,
    },
    border = {
      style = "single",
      text = {
        top = "[LSP attached]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }

  local lsp_names = M.get_attached_lsp()

  -- NOTE: the target mounts an empty menu when nothing is attached, which gives
  -- you a blank box with no way to tell it apart from a broken one.
  if #lsp_names == 0 then
    vim.notify("No LSP attached to this buffer", vim.log.levels.INFO, { title = "nvim-config" })
    return
  end

  local menu_items = {}
  for _, name in ipairs(lsp_names) do
    local line = NuiLine()
    line:append(string.format(" %s %s", symbol_icon.lsp.icon, name))
    table.insert(menu_items, Menu.item(line))
  end

  local menu_options = {
    lines = menu_items,
    max_width = 30,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
  }

  Menu(popup_options, menu_options):mount()
end

--- When several servers attach to one filetype, this is the one worth naming
--- first in the statusline.
M.main_lsp_by_filetype = {
  lua = "lua_ls",
  nix = "nixd",
  python = "pyright",
  elm = "elmls",
}

return M
