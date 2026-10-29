local fn = vim.fn
local api = vim.api

local utils = require("utils")

-- Warn when the file we just opened is not utf-8.
api.nvim_create_autocmd({ "BufRead" }, {
  pattern = "*",
  group = api.nvim_create_augroup("non_utf8_file", { clear = true }),
  callback = function()
    if vim.bo.fileencoding ~= "utf-8" then
      vim.notify("File not in UTF-8 format!", vim.log.levels.WARN, { title = "nvim-config" })
    end
  end,
})

-- highlight the yanked region, see `:h lua-highlight`
local yank_group = api.nvim_create_augroup("highlight_yank", { clear = true })
api.nvim_create_autocmd({ "TextYankPost" }, {
  pattern = "*",
  group = yank_group,
  callback = function()
    vim.hl.on_yank { higroup = "YankColor", timeout = 300 }
  end,
})

api.nvim_create_autocmd({ "CursorMoved" }, {
  pattern = "*",
  group = yank_group,
  callback = function()
    vim.g.current_cursor_pos = vim.fn.getcurpos()
  end,
})

-- keep the cursor where it was when yanking, instead of jumping to the start
api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  group = yank_group,
  callback = function()
    if vim.v.event.operator == "y" then
      vim.fn.setpos(".", vim.g.current_cursor_pos)
    end
  end,
})

-- Create intermediate directories when saving to a path that does not exist yet
api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = "*",
  group = api.nvim_create_augroup("auto_create_dir", { clear = true }),
  callback = function(ctx)
    local dir = fn.fnamemodify(ctx.file, ":p:h")
    utils.may_create_dir(dir)
  end,
})

-- Reload the file if it changed outside of nvim. `checktime`
api.nvim_create_augroup("auto_read", { clear = true })

api.nvim_create_autocmd({ "FileChangedShellPost" }, {
  pattern = "*",
  group = "auto_read",
  callback = function()
    vim.notify(
      "File changed on disk. Buffer reloaded!",
      vim.log.levels.WARN,
      { title = "nvim-config" }
    )
  end,
})

api.nvim_create_autocmd({ "FocusGained", "CursorHold" }, {
  pattern = "*",
  group = "auto_read",
  callback = function()
    if fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- Equalize window sizes when the terminal is resized
api.nvim_create_autocmd("VimResized", {
  group = api.nvim_create_augroup("win_autoresize", { clear = true }),
  desc = "autoresize windows on resizing operation",
  command = "wincmd =",
})

-- Open nvim-tree when nvim is launched with a directory argument. This module
-- is required before plugin_specs, so the autocmd exists well before VimEnter;
-- the `require` below is what lazy-loads nvim-tree on demand.
local function open_nvim_tree(data)
  -- check if buffer is a directory
  local directory = vim.fn.isdirectory(data.file) == 1

  if not directory then
    return
  end

  -- replace the directory buffer with an empty one
  vim.cmd.enew()
  vim.cmd.bw(data.buf)

  require("nvim-tree.api").tree.open()
end

api.nvim_create_autocmd({ "VimEnter" }, {
  group = api.nvim_create_augroup("nvim_tree_open_dir", { clear = true }),
  desc = "open nvim-tree when nvim is given a directory",
  callback = open_nvim_tree,
})

-- Do not use smart case in command line mode
api.nvim_create_augroup("dynamic_smartcase", { clear = true })
api.nvim_create_autocmd("CmdlineEnter", {
  group = "dynamic_smartcase",
  pattern = ":",
  callback = function()
    vim.o.smartcase = false
  end,
})

api.nvim_create_autocmd("CmdlineLeave", {
  group = "dynamic_smartcase",
  pattern = ":",
  callback = function()
    vim.o.smartcase = true
  end,
})

api.nvim_create_autocmd("TermOpen", {
  group = api.nvim_create_augroup("term_start", { clear = true }),
  pattern = "*",
  callback = function(args)
    -- for the ansi preview buffer, insert is not possible
    if vim.b[args.buf].ansi_preview then
      return
    end

    -- Do not use number and relative number for terminal inside nvim
    vim.wo.relativenumber = false
    vim.wo.number = false

    -- Go to insert mode by default to start typing command
    vim.cmd("startinsert")
  end,
})

-- Absolute line numbers in insert mode and in inactive windows, relative
-- everywhere else.
local number_toggle_group = api.nvim_create_augroup("numbertoggle", { clear = true })
api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
  pattern = "*",
  group = number_toggle_group,
  desc = "toggle line number",
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = true
    end
  end,
})

api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
  group = number_toggle_group,
  desc = "toggle line number",
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
  end,
})

-- This module loads before `ui`, so the hook is registered before the
-- colorscheme is applied -- that ordering is the whole point, see init.lua.
api.nvim_create_autocmd("ColorScheme", {
  group = api.nvim_create_augroup("custom_highlight", { clear = true }),
  pattern = "*",
  desc = "Define or override some highlight groups",
  callback = function()
    -- For yank highlight
    vim.api.nvim_set_hl(
      0,
      "YankColor",
      { fg = "#34495E", bg = "#2ECC71", ctermfg = 59, ctermbg = 41 }
    )

    -- For cursor colors, referenced by `guicursor` in options.lua
    vim.api.nvim_set_hl(0, "Cursor", { fg = "black", bg = "#00c918", update = true })
    vim.api.nvim_set_hl(0, "Cursor2", { fg = "None", bg = "yellow", update = true })

    -- For floating window borders
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "None", fg = "LightGreen", update = true })

    -- transparent background for floats, so they blend better
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "None", update = true })

    -- the highlight used for the cmdline completion window border
    vim.api.nvim_set_hl(0, "Pmenu", { bg = "None", update = true })

    -- highlight for matching parentheses
    vim.api.nvim_set_hl(0, "MatchParen", { bold = true, underline = true, update = true })

    -- vim-illuminate, Stage 10. Harmless to define before the plugin exists.
    vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { reverse = true, update = true })
    vim.api.nvim_set_hl(0, "IlluminatedWordRead", { reverse = true, update = true })
    vim.api.nvim_set_hl(0, "IlluminatedWordText", { reverse = true, update = true })

    -- Let the terminal background show through
    local transparent = {
      "Normal",
      "NormalNC",
      "SignColumn",
      "NvimTreeNormal",
      "NvimTreeNormalNC",
      "TabLine",
      "TabLineSel",
      "TabLineFill",
    }

    for _, group in ipairs(transparent) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      hl.bg = "none"
      vim.api.nvim_set_hl(0, group, hl)
    end

    vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = "none", fg = "#a3a3a3" })
  end,
})

-- Detect whether we are in a git repo.
api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  group = api.nvim_create_augroup("git_repo_check", { clear = true }),
  pattern = "*",
  desc = "check if we are inside Git repo",
  callback = function()
    utils.inside_git_repo()
  end,
})

-- Make very large files usable: skip the expensive per-buffer machinery.
api.nvim_create_autocmd("BufReadPre", {
  group = api.nvim_create_augroup("large_file", { clear = true }),
  pattern = "*",
  desc = "optimize for large file",
  callback = function(ev)
    local file_size_limit = 4.0 -- unit in MB
    local fpath = ev.file

    local filesize = utils.filesize(fpath)

    if filesize and filesize / (1024 * 1024) > file_size_limit then
      vim.o.eventignore = "all"

      -- show ruler
      vim.o.ruler = true

      --  turning off relative number helps a lot
      vim.wo.relativenumber = false
      vim.wo.number = false

      vim.bo.swapfile = false
      vim.bo.bufhidden = "unload"
      vim.bo.undolevels = -1
    end
  end,
})

