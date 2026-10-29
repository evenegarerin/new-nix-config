-- LSP setup. Uses the native `vim.lsp.config` / `vim.lsp.enable` API (nvim 0.11+);
-- nvim-lspconfig is present only to supply each server's default `cmd`,
-- `root_markers` and `filetypes`. Per-server overrides live in `after/lsp/`.
local utils = require("utils")
local lsp_utils = require("lsp_utils")

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_buf_conf", { clear = true }),
  callback = function(event_context)
    local client = vim.lsp.get_client_by_id(event_context.data.client_id)

    if not client then
      return
    end

    local bufnr = event_context.buf

    local map = function(mode, l, r, opts)
      opts = opts or {}
      opts.silent = true
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map("n", "gd", function()
      vim.lsp.buf.definition {
        on_list = function(options)
          -- Collapse duplicate definitions for `local M.fn = function() ... end`,
          -- which otherwise reports the same line twice.
          local unique_defs = {}
          local def_loc_hash = {}

          for _, def_location in pairs(options.items) do
            local hash_key = def_location.filename .. def_location.lnum

            if not def_loc_hash[hash_key] then
              def_loc_hash[hash_key] = true
              table.insert(unique_defs, def_location)
            end
          end

          options.items = unique_defs

          ---@diagnostic disable-next-line: param-type-mismatch
          vim.fn.setloclist(0, {}, " ", options)

          -- jump straight there when there is only one
          if #options.items > 1 then
            vim.cmd.lopen()
          else
            vim.cmd([[silent! lfirst]])
          end
        end,
      }
    end, { desc = "go to definition" })

    map("n", "<leader>ld", vim.lsp.buf.definition, { desc = "go to definition" })

    map("n", "K", function()
      vim.lsp.buf.hover {
        border = "single",
        max_height = 40,
        max_width = 100,
        close_events = { "CursorMoved", "BufLeave", "WinLeave", "LSPDetach" },
      }
    end, { desc = "hover" })

    map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "signature help" })

    map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP rename" })
    map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
    map("n", "<leader>lf", function()
      vim.lsp.buf.format { async = true }
    end, { desc = "LSP format buffer" })
    map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "add workspace folder" })
    map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "remove workspace folder" })
    map("n", "<leader>lwl", function()
      vim.print(vim.lsp.buf.list_workspace_folders())
    end, { desc = "list workspace folders" })

    -- ruff and pyright both answer hover; pyright's is better.
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
  nested = true,
  desc = "Configure buffer keymap and behavior based on LSP",
})

-- `*` is the base config every server is merged on top of
vim.lsp.config("*", {
  capabilities = lsp_utils.get_default_capabilities(),
  flags = {
    debounce_text_changes = 150,
  },
})

-- server name (as nvim-lspconfig knows it) -> the executable it needs.
local enabled_lsp_servers = {
  nixd = { exe = "nixd", optional = false },
  lua_ls = { exe = "lua-language-server", optional = false },

  elmls = { exe = "elm-language-server", optional = true },
  ts_ls = { exe = "typescript-language-server", optional = true },
  bashls = { exe = "bash-language-server", optional = true },
  yamlls = { exe = "yaml-language-server", optional = true },
  marksman = { exe = "marksman", optional = true },

  pyright = { exe = "pyright-langserver", optional = true },
  ruff = { exe = "ruff", optional = true },
}

local missing = {}

for server_name, server_info in pairs(enabled_lsp_servers) do
  if utils.executable(server_info.exe) then
    vim.lsp.enable(server_name)
  elseif not server_info.optional then
    table.insert(missing, string.format("%s (%s)", server_name, server_info.exe))
  end
end

if #missing > 0 then
  table.sort(missing)
  vim.schedule(function()
    vim.notify(
      string.format("LSP server(s) not on PATH, not enabled: %s", table.concat(missing, ", ")),
      vim.log.levels.WARN,
      { title = "nvim-config" }
    )
  end)
end

------------------------------------------------------------------------
--                          LSP commands                              --
------------------------------------------------------------------------

vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {
  desc = "Show LSP Info",
})

vim.api.nvim_create_user_command("LspLog", function(_)
  vim.cmd(string.format("edit %s", vim.lsp.log.get_filename()))
end, {
  desc = "Show LSP log",
})

-- `vim.lsp.enable` registration survives.
vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients { bufnr = 0 }

  if #clients == 0 then
    vim.notify("No LSP attached to this buffer", vim.log.levels.INFO, { title = "nvim-config" })
    return
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
    client:stop()
  end

  vim.defer_fn(function()
    vim.cmd("silent! edit")
    vim.notify(
      string.format("Restarted: %s", table.concat(names, ", ")),
      vim.log.levels.INFO,
      { title = "nvim-config" }
    )
  end, 500)
end, {
  desc = "Restart the LSP servers attached to this buffer",
})


--- LSP progress in the message area
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local value = ev.data.params.value
    vim.api.nvim_echo({ { value.message or "done" } }, false, {
      id = "lsp." .. ev.data.client_id,
      kind = "progress",
      source = "vim.lsp",
      title = value.title,
      status = value.kind ~= "end" and "running" or "success",
      percent = value.percentage,
    })
  end,
})

vim.g.lsp_inlay_hint_enabled = false

vim.api.nvim_create_user_command("LspInlayHints", function(context)
  if context["args"] == "enable" then
    vim.g.lsp_inlay_hint_enabled = true
  end

  if context["args"] == "disable" then
    vim.g.lsp_inlay_hint_enabled = false
  end

  vim.lsp.inlay_hint.enable(vim.g.lsp_inlay_hint_enabled)
end, {
  bang = false,
  nargs = 1,
  force = true,
  desc = "Toggle LSP inlayHints",
  complete = function()
    return { "enable", "disable" }
  end,
})

vim.api.nvim_create_user_command("LspAttached", function()
  local size = {
    width = 40,
    height = 10,
  }

  local win_width, win_height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

  lsp_utils.show_lsp_menu(size, {
    col = math.floor(win_width / 2 - size.width / 2),
    row = math.floor(win_height / 2 - size.height / 2),
  })
end, {
  desc = "Show LSP attached to current buffer",
})
