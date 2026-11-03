local api = require("nvim-tree.api")
local symbol_icon = require("symbol_icon")

-- Auto-preview: show the node under the cursor in the target window while focus stays within the tree
local auto_preview = { enabled = false, last = nil }
local preview_timer = vim.uv.new_timer()

local function preview_under_cursor()
  if not auto_preview.enabled then
    return
  end

  -- the cursor may have left the tree during the debounce window
  if not api.tree.is_tree_buf() then
    return
  end

  -- the live filter (`<C-f>`) and visual mode both move the cursor; stay out of the way
  if vim.fn.mode() ~= "n" then
    return
  end

  local node = api.tree.get_node_under_cursor()

  -- `.nodes` marks directories, directory symlinks and the root -- `node.type`
  -- cannot be used here, a symlink reads as "link" either way.
  if not node or node.nodes ~= nil or node.name == ".." then
    return
  end

  -- a purely horizontal move, or a redraw, should not reopen what is on screen
  if node.absolute_path == auto_preview.last then
    return
  end

  auto_preview.last = node.absolute_path
  api.node.open.preview_no_picker(node)
end

require("nvim-tree").setup {
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    api.config.mappings.default_on_attach(bufnr)

    -- free `f` so the global hop mapping reaches the tree
    vim.keymap.del("n", "f", { buffer = bufnr })
    vim.keymap.set("n", "<C-f>", api.live_filter.start,
      { buffer = bufnr, desc = "nvim-tree: live filter" })

    -- `clear = false`: on_attach runs once per tree buffer, and a clearing
    -- augroup would drop the previous buffer's autocmd when a second tree
    -- buffer (another tab) appears.
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = bufnr,
      group = vim.api.nvim_create_augroup("nvim_tree_auto_preview", { clear = false }),
      desc = "nvim-tree: preview node under cursor",
      callback = function()
        if not auto_preview.enabled then
          return
        end
        preview_timer:stop()
        preview_timer:start(80, 0, vim.schedule_wrap(preview_under_cursor))
      end,
    })
  end,

  diagnostics = {
    enable = true,

    show_on_dirs = true,
    show_on_open_dirs = true,

    -- Same glyphs as the statuscolumn gutter and lualine; nvim-tree spells
    -- the warn key `warning`.
    icons = {
      hint = symbol_icon.diagnostic.hint,
      info = symbol_icon.diagnostic.info,
      warning = symbol_icon.diagnostic.warn,
      error = symbol_icon.diagnostic.error,
    },
  },
}

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>ee", api.tree.toggle, "nvim-tree: toggle")
map("<leader>ef", function()
  if api.tree.is_tree_buf() then
      vim.cmd.wincmd("p")
  else
    api.tree.focus()
  end
end, "nvim-tree: toggle focus")
map("<leader>eg", api.tree.change_root_to_node, "nvim-tree: cd to node")
map("<leader>es", function()
  api.tree.find_file { open = true, focus = true, update_root = true }
end, "nvim-tree: reveal current file")
map("<leader>ec", api.tree.collapse_all, "nvim-tree: collapse all")
map("<leader>ep", function()
  auto_preview.enabled = not auto_preview.enabled
  -- so that re-enabling always previews the node we are sitting on
  auto_preview.last = nil

  vim.notify(
    "nvim-tree auto-preview " .. (auto_preview.enabled and "on" or "off"),
    vim.log.levels.INFO,
    { title = "nvim-config" }
  )

  if auto_preview.enabled then
    preview_under_cursor()
  end
end, "nvim-tree: toggle auto preview")
