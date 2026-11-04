local M = {}

-- Published before the rest of this file runs, so that the re-entrant
-- `require("config.conform")` coming from lazy.nvim's `config` hook (see the
-- spec in plugin_specs.lua) gets this table back instead of executing this file
-- a second time. <leader>w in mappings.lua requires this module directly, and
-- that is what pulls the plugin in on an unmodified buffer, where no
-- BufWritePre ever fires.
package.loaded["config.conform"] = M

local utils = require("utils")

local notify_opts = { title = "nvim-config" }

-- Filetypes that are never formatted on save. Prose, git buffers and anything
-- whose layout is significant (recipes in make/just files are tab-sensitive).
local exempt_filetypes = {
  text = true,
  gitcommit = true,
  gitrebase = true,
  help = true,
  man = true,
  markdown = true,
  sql = true,
  csv = true,
  tsv = true,
  log = true,
  make = true,
  just = true,
}

-- Same idea, but keyed on the file name instead of the filetype: generated or
-- machine-owned files that should never be rewritten by hand. Lua patterns,
-- matched against the basename.
local exempt_filenames = {
  "^Makefile$",
  "^GNUmakefile$",
  "%.mk$",
  "^[Jj]ustfile$",
  "^%.justfile$",
  "%.min%.js$",
  "%.min%.css$",
  "%-lock%.json$", -- package-lock.json and friends
  "%.lock$", -- flake.lock, Cargo.lock, yarn.lock, ...
}

-- Formatting a huge file blocks the write for as long as the formatter runs.
local max_filesize = 1024 * 1024 -- unit in bytes, so 1MB

-- `["_"] = { "prettier" }` below makes prettier the formatter for *every*
-- filetype without a dedicated one. Prettier only knows a fixed set of parsers
-- though, and exits with "No parser could be inferred for file" on anything
-- else (.conf, .service, .env, vim, zsh, ...), which would mean an error
-- notification on every single save. So only let it run where it can actually
-- do something; everything else falls through to lsp_format = "fallback".
local prettier_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  json = true,
  jsonc = true,
  json5 = true,
  css = true,
  scss = true,
  less = true,
  html = true,
  vue = true,
  svelte = true,
  yaml = true,
  graphql = true,
  handlebars = true,
  markdown = true,
  ["markdown.mdx"] = true,
}

--- Decide whether this buffer should be formatted, and with which options.
--- Used both as conform's `format_on_save` hook and by `M.write()` below, so
--- that <leader>w honours exactly the same exemptions as a plain `:w`.
--- Returning nil tells conform to skip the buffer entirely.
--- @param bufnr integer
--- @return table|nil
function M.should_format(bufnr)
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return nil
  end

  -- terminals, quickfix, fugitive buffers and the like
  if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
    return nil
  end

  if exempt_filetypes[vim.bo[bufnr].filetype] then
    return nil
  end

  local fpath = vim.api.nvim_buf_get_name(bufnr)
  local basename = vim.fn.fnamemodify(fpath, ":t")

  for _, pattern in ipairs(exempt_filenames) do
    if basename:match(pattern) then
      return nil
    end
  end

  local filesize = utils.filesize(fpath)
  if filesize and filesize > max_filesize then
    return nil
  end

  return { timeout_ms = 1000, lsp_format = "fallback" }
end

--- What <leader>w runs. `:update` only writes, and so only triggers format on
--- save, when the buffer is actually modified -- press it twice and the second
--- press is a no-op. Format an unmodified buffer explicitly instead, so
--- <leader>w always formats regardless of whether there was anything to save.
function M.write()
  local bufnr = vim.api.nvim_get_current_buf()

  if vim.bo[bufnr].modified then
    -- BufWritePre -> conform's format on save, nothing else to do here
    vim.cmd("update")
    return
  end

  local opts = M.should_format(bufnr)
  if not opts then
    return
  end

  opts.bufnr = bufnr
  require("conform").format(opts)

  -- Only true if the formatter actually changed something.
  if vim.bo[bufnr].modified then
    vim.cmd("update")
  end
end

require("conform").setup {
  formatters_by_ft = {
    nix = { "nixfmt" },
    lua = { "stylua" },
    python = { "ruff_organize_imports", "ruff_format" },
    elm = { "elm_format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    toml = { "taplo" },
    qml = { "qmlformat" },

    -- Catch-all: any filetype not listed above gets prettier, subject to the
    -- condition on the formatter below.
    ["_"] = { "prettier" },
  },

  formatters = {
    qmlformat = {
      -- Qt defaults to 4 spaces; the rest of this repo indents with 2.
      prepend_args = { "--indent-width", "2" },
    },

    prettier = {
      condition = function(_, ctx)
        return prettier_filetypes[vim.bo[ctx.buf].filetype] == true
      end,
    },
  },

  format_on_save = M.should_format,

  -- A buffer with nothing to run is the normal case here, not a problem.
  notify_no_formatters = false,
}

-- Escape hatch for when a file must be saved exactly as-is, e.g. when touching
-- a vendored file in a repo that does not share these formatter settings.
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true
    vim.notify("format on save disabled for this buffer", vim.log.levels.INFO, notify_opts)
  else
    vim.g.disable_autoformat = true
    vim.notify("format on save disabled globally", vim.log.levels.INFO, notify_opts)
  end
end, {
  desc = "Disable format on save (! for current buffer only)",
  bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
  vim.notify("format on save enabled", vim.log.levels.INFO, notify_opts)
end, {
  desc = "Re-enable format on save",
})

return M
