local gs = require("gitsigns")
local symbol_icon = require("symbol_icon")

gs.setup {
  signs = {
    add = { text = symbol_icon.git.diff.added },
    change = { text = symbol_icon.git.diff.modified },
    delete = { text = symbol_icon.git.diff.delete },
    topdelete = { text = symbol_icon.git.diff.topdelete },
    changedelete = { text = symbol_icon.git.diff.changedelete },
  },
  word_diff = false,
  on_attach = function(bufnr)
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map("n", "]c", function()
      if vim.wo.diff then
        return "]c"
      end
      vim.schedule(function()
        gs.nav_hunk("next")
      end)
      return "<Ignore>"
    end, { expr = true, desc = "next hunk" })

    map("n", "[c", function()
      if vim.wo.diff then
        return "[c"
      end
      vim.schedule(function()
        gs.nav_hunk("prev")
      end)
      return "<Ignore>"
    end, { expr = true, desc = "previous hunk" })

    -- Actions
    map("n", "<leader>hp", gs.preview_hunk, { desc = "preview hunk" })
    map("n", "<leader>hb", function()
      gs.blame_line { full = true }
    end, { desc = "blame hunk" })

    -- NOTE: the target stops here -- it has no staging maps at all, despite
    -- staging being the main reason to run gitsigns. These fill the gap, under
    -- the same <leader>h prefix.
    map("n", "<leader>hs", gs.stage_hunk, { desc = "stage hunk" })
    map("n", "<leader>hr", gs.reset_hunk, { desc = "reset hunk" })

    map("v", "<leader>hs", function()
      gs.stage_hunk { vim.fn.line("."), vim.fn.line("v") }
    end, { desc = "stage selected hunk" })
    map("v", "<leader>hr", function()
      gs.reset_hunk { vim.fn.line("."), vim.fn.line("v") }
    end, { desc = "reset selected hunk" })

    map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
    map("n", "<leader>hS", gs.stage_buffer, { desc = "stage whole buffer" })
    map("n", "<leader>hR", gs.reset_buffer, { desc = "reset whole buffer" })
  end,
}

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.cmd([[
      hi GitSignsChangeInline gui=reverse
      hi GitSignsAddInline gui=reverse
      hi GitSignsDeleteInline gui=reverse
    ]])
  end,
})
