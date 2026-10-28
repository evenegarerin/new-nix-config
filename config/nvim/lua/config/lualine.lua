local utils = require("utils")
local lsp_utils = require("lsp_utils")
local symbol_icon = require("symbol_icon")
local fn = vim.fn

local BRANCH_MAX_LEN = 30

local TRAILING_SCAN_MAX_LINES = 10000

local function show_fileformat()
  local fileformat = vim.api.nvim_get_option_value("fileformat", { buf = 0 })

  -- unix is the common case and carries no information
  if fileformat == "unix" then
    return ""
  end

  return symbol_icon.fileformat[fileformat]
end

local function spell()
  if vim.o.spell then
    return "[SPELL]"
  end

  return ""
end

--- Line number of the first line with trailing whitespace, if any.
local function trailing_space()
  if vim.api.nvim_get_mode().mode == "i" then
    return ""
  end

  if not vim.o.modifiable then
    return ""
  end

  local line_count = vim.api.nvim_buf_line_count(0)
  if line_count > TRAILING_SCAN_MAX_LINES then
    return ""
  end

  for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:find("%s$") then
      return string.format("[%d]trailing", i)
    end
  end

  return ""
end

local function show_encoding()
  local fileencoding = vim.api.nvim_get_option_value("fileencoding", { buf = 0 })
  fileencoding = string.upper(fileencoding)

  if fileencoding ~= "UTF-8" then
    return fileencoding
  end

  return ""
end

local function mixed_indent()
  if not vim.o.modifiable then
    return ""
  end

  local space_pat = [[\v^ +]]
  local tab_pat = [[\v^\t+]]
  local space_indent = fn.search(space_pat, "nwc")
  local tab_indent = fn.search(tab_pat, "nwc")
  local mixed = (space_indent > 0 and tab_indent > 0)
  local mixed_same_line
  if not mixed then
    mixed_same_line = fn.search([[\v^(\t+ | +\t)]], "nwc")
    mixed = mixed_same_line > 0
  end
  if not mixed then
    return ""
  end
  if mixed_same_line ~= nil and mixed_same_line > 0 then
    return "MI:" .. mixed_same_line
  end
  local space_indent_cnt = fn.searchcount({ pattern = space_pat, max_count = 1e3 }).total
  local tab_indent_cnt = fn.searchcount({ pattern = tab_pat, max_count = 1e3 }).total
  if space_indent_cnt > tab_indent_cnt then
    return "MI:" .. tab_indent
  else
    return "MI:" .. space_indent
  end
end

local function virtual_env()
  return utils.get_virtual_env()
end

local diff = function()
  local git_status = vim.b.gitsigns_status_dict
  if git_status == nil then
    return
  end

  return {
    added = git_status.added,
    modified = git_status.changed,
    removed = git_status.removed,
  }
end

local get_active_lsp = function()
  local lsp_names_unordered = lsp_utils.get_attached_lsp()
  if next(lsp_names_unordered) == nil then
    return symbol_icon.lsp.not_exist
  end

  local main_lsp = lsp_utils.main_lsp_by_filetype[vim.bo.filetype]
  local client_names = utils.reorder_list_element(lsp_names_unordered, main_lsp)

  local cnt = #client_names
  if cnt == 1 then
    return client_names[1]
  end

  return string.format("%s (+%s)", client_names[1], cnt - 1)
end

--- Click the LSP name for the same popup `:LspAttached` shows.
local show_lsp_menu = function()
  local size = { width = 20, height = 5 }

  local win_width, win_height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

  lsp_utils.show_lsp_menu(size, {
    col = win_width - size.width - 5,
    row = win_height - size.height - 2,
  })
end

--- Click the branch name to get a checkout menu of local and remote branches.
local show_branch_menu = function()
  local Menu = require("nui.menu")

  local height = 5
  local win_height = vim.api.nvim_win_get_height(0)

  --- @type nui_popup_options
  local popup_options = {
    relative = "win",
    position = {
      row = win_height - height - 2,
      col = 10,
    },
    size = {
      width = 50,
      height = height,
    },
    border = {
      style = "single",
      text = {
        top = "[Git branches]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }

  local branch_info = utils.get_git_branches()
  local local_branches = branch_info["local"]
  local remote_branches = branch_info["remote"]

  if #local_branches == 0 and #remote_branches == 0 then
    return
  end

  local as_items = function(branches)
    return vim
      .iter(branches)
      :map(function(v)
        return Menu.item(string.format(" %s %s", symbol_icon.git.branch, v), {
          is_local = vim.list_contains(local_branches, v),
        })
      end)
      :totable()
  end

  local menu_items = as_items(local_branches)

  if #remote_branches > 0 then
    table.insert(
      menu_items,
      Menu.separator("Remote", { char = "-", text_align = "center" })
    )
    vim.list_extend(menu_items, as_items(remote_branches))
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
    on_submit = function(item)
      -- the label is " <icon> <branch>"; the branch name is the last field
      local branch_name = vim.split(item.text, " ", { trimempty = true })[2]

      local cmd = item.is_local and { "git", "checkout", branch_name }
        or { "git", "checkout", "--track", branch_name }

      local r = vim.system(cmd, { text = true }):wait()
      if r.code ~= 0 then
        vim.notify(
          string.format("failed to switch branch: %s", r.stderr),
          vim.log.levels.ERROR
        )
      end
    end,
  }

  Menu(popup_options, menu_options):mount()
end

require("lualine").setup {
  options = {
    icons_enabled = true,
    theme = "auto",
    component_separators = symbol_icon.statusline.component_separators,
    section_separators = symbol_icon.statusline.section_separators,
    disabled_filetypes = {},
    always_divide_middle = false,
    refresh = {
      statusline = 1000,
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      {
        "branch",
        icon = symbol_icon.git.branch,
        fmt = function(name, _)
          -- truncate in case the branch name is very long
          return string.sub(name, 1, BRANCH_MAX_LEN)
        end,
        color = { gui = "italic,bold" },
        on_click = show_branch_menu,
      },
      {
        virtual_env,
        icon = symbol_icon.python,
      },
      {
        "diff",
        symbols = symbol_icon.git.diff,
        source = diff,
      },
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = symbol_icon.diagnostic,
        color = { gui = "bold" },
      },
    },
    lualine_c = {
      {
        "filename",
        path = 1, -- relative to cwd
        symbols = {
          readonly = symbol_icon.file.readonly,
        },
      },
      {
        spell,
        color = { fg = "black", bg = "#a7c080" },
      },
      {
        -- the partially typed command
        "%S",
        color = { gui = "bold", fg = "cyan" },
      },
    },
    lualine_x = {
      {
        trailing_space,
        color = "WarningMsg",
      },
      {
        mixed_indent,
        color = "WarningMsg",
      },
      {
        get_active_lsp,
        icon = symbol_icon.lsp.icon,
        on_click = show_lsp_menu,
      },
    },
    lualine_y = {
      {
        show_encoding,
        color = "ErrorMsg",
      },
      {
        show_fileformat,
        color = "ErrorMsg",
      },
    },
    lualine_z = { "progress" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  extensions = { "quickfix", "fugitive", "nvim-tree" },
}