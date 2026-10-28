-- Plugin-independent keymaps. From ../nvim.bak/lua/mappings.lua; entries that
-- call into autoload/*.vim are commented out until Stage 2 copies those files
-- (calling one without its autoload file gives E117 only when you press the key).
local keymap = vim.keymap
local uv = vim.uv

-- Save key strokes: no shift needed to reach the command line.
-- NOTE: this costs `;` as repeat-f. Stage 10's hop.nvim takes over `f` anyway.
keymap.set({ "n", "x" }, ";", ":")

-- Turn the word under cursor to upper case
keymap.set("i", "<c-u>", "<Esc>viwUea")

-- Turn the current word into title case
keymap.set("i", "<c-t>", "<Esc>b~lea")

-- Paste non-linewise text above or below the current line
keymap.set("n", "<leader>p", "m`o<ESC>p``", { desc = "paste below current line" })
keymap.set("n", "<leader>P", "m`O<ESC>p``", { desc = "paste above current line" })

keymap.set("n", "<leader>w", "<cmd>update<cr>", { silent = true, desc = "save buffer" })
keymap.set("n", "<leader>q", "<cmd>x<cr>", { silent = true, desc = "quit current window" })
keymap.set("n", "<leader>Q", "<cmd>qa!<cr>", { silent = true, desc = "quit nvim" })

keymap.set("n", [[\x]], "<cmd>windo lclose <bar> cclose <cr>", {
  silent = true,
  desc = "close qf and location list",
})

-- Delete a buffer without closing the window
keymap.set("n", [[\db]], "<cmd>bprevious <bar> bdelete #<cr>", {
  silent = true,
  desc = "Delete current buffer",
})

keymap.set("n", [[\dB]], function()
  local buf_ids = vim.api.nvim_list_bufs()
  local cur_buf = vim.api.nvim_win_get_buf(0)

  for _, buf_id in pairs(buf_ids) do
    -- do not delete unlisted buffers, which may lead to unexpected errors
    if vim.api.nvim_get_option_value("buflisted", { buf = buf_id }) and buf_id ~= cur_buf then
      vim.api.nvim_buf_delete(buf_id, { force = true })
    end
  end
end, { desc = "Delete other buffers" })

keymap.set("n", [[\dt]], "<cmd>tabclose<CR>", { silent = true, desc = "Delete current tab" })
keymap.set("n", [[\dT]], "<cmd>tabonly<CR>", { silent = true, desc = "Delete other tabs" })

-- Move by screen line, but only when no count was given, so `5j` and the
-- relativenumber jumps keep working on real lines.
keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Do not include trailing white space when using $ in visual mode
keymap.set("x", "$", "g_")

-- Go to start or end of line easier
keymap.set({ "n", "x" }, "H", "^")
keymap.set({ "n", "x" }, "L", "g_")

-- Continuous visual shifting (does not exit visual mode)
keymap.set("x", "<", "<gv")
keymap.set("x", ">", ">gv")

keymap.set("n", "<leader>v", "printf('`[%s`]', getregtype()[0])", {
  expr = true,
  desc = "reselect last pasted area",
})

keymap.set("n", "<leader>cd", "<cmd>lcd %:p:h<cr><cmd>pwd<cr>", { desc = "change cwd" })

-- Use Esc to quit the builtin terminal
keymap.set("t", "<Esc>", [[<c-\><c-n>]])

keymap.set("n", "<F11>", "<cmd>set spell!<cr>", { desc = "toggle spell" })
keymap.set("i", "<F11>", "<c-o><cmd>set spell!<cr>", { desc = "toggle spell" })

-- Change text without putting it into the register
keymap.set("n", "c", '"_c')
keymap.set("n", "C", '"_C')
keymap.set("n", "cc", '"_cc')
keymap.set("x", "c", '"_c')

-- Replace a visual selection without clobbering the register
keymap.set("x", "p", '"_c<Esc>p')

keymap.set("n", "<leader>y", "<cmd>%yank<cr>", { desc = "yank entire buffer" })

-- Switch windows
keymap.set("n", "<Left>", "<C-W>h")
keymap.set("n", "<Right>", "<C-W>l")
keymap.set("n", "<Up>", "<C-W>k")
keymap.set("n", "<Down>", "<C-W>j")

-- Do not move the cursor when joining lines.
keymap.set("n", "J", function()
  vim.cmd([[
      normal! mzJ`z
      delmarks z
    ]])
end, { desc = "join lines without moving cursor" })

keymap.set("n", "gJ", function()
  -- `normal!` so this does not recurse into the mapping above
  vim.cmd([[
      normal! mzgJ`z
      delmarks z
    ]])
end, { desc = "join lines without moving cursor" })

-- Break inserted text into smaller undo units at punctuation.
local undo_ch = { ",", ".", "!", "?", ";", ":" }
for _, ch in ipairs(undo_ch) do
  keymap.set("i", ch, ch .. "<c-g>u")
end

-- insert a semicolon at the end of the line
keymap.set("i", "<A-;>", "<Esc>miA;<Esc>`ii")

-- Beginning and end of line in insert mode
keymap.set("i", "<C-A>", "<HOME>")
keymap.set("i", "<C-E>", "<END>")
keymap.set("c", "<C-A>", "<HOME>")

-- Delete the character to the right of the cursor
keymap.set("i", "<C-D>", "<DEL>")

keymap.set("n", "<leader>cb", function()
  local cnt = 0
  local blink_times = 7
  local timer = uv.new_timer()
  if timer == nil then
    return
  end

  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      vim.cmd([[
      set cursorcolumn!
      set cursorline!
    ]])

      if cnt == blink_times then
        timer:close()
      end

      cnt = cnt + 1
    end)
  )
end, { desc = "show cursor" })

-- Stop accidental macro recording: `q` reminds you, `Q` records.
-- NOTE: plugins that set a buffer-local `q` still win -- nvim-tree closes on it.
-- Help and quickfix do NOT: stock nvim maps nothing there, so `q` was
-- macro-record and is now the reminder. Use `\x` for quickfix/loclist,
-- `<leader>q` for any window, `:helpclose` for help.
keymap.set("n", "q", function()
  vim.print("q is remapped to Q in Normal mode!")
end)
keymap.set("n", "Q", "q", { desc = "Record macro" })

keymap.set("n", "<Esc>", function()
  -- NOTE: the target calls `vim.cmd("fclose!")` bare. With no floating window
  -- open that throws E444, so plain <Esc> in normal mode would error.
  pcall(vim.cmd, "fclose!")
end, { desc = "close floating win" })

-- Toggle cursor column
keymap.set(
  "n",
  "<leader>cl",
  "<cmd>call utils#ToggleCursorCol()<cr>",
  { desc = "toggle cursor column" }
)

-- Move the current line up and down
keymap.set(
  "n",
  "<A-k>",
  '<cmd>call utils#SwitchLine(line("."), "up")<cr>',
  { desc = "move line up" }
)
keymap.set(
  "n",
  "<A-j>",
  '<cmd>call utils#SwitchLine(line("."), "down")<cr>',
  { desc = "move line down" }
)

-- Move the current visual-line selection up and down
keymap.set("x", "<A-k>", '<cmd>call utils#MoveSelection("up")<cr>', { desc = "move selection up" })
keymap.set(
  "x",
  "<A-j>",
  '<cmd>call utils#MoveSelection("down")<cr>',
  { desc = "move selection down" }
)

-- Go to a certain buffer by count, e.g. `3gb`
keymap.set("n", "gb", '<cmd>call buf_utils#GoToBuffer(v:count, "forward")<cr>', {
  desc = "go to buffer (forward)",
})
keymap.set("n", "gB", '<cmd>call buf_utils#GoToBuffer(v:count, "backward")<cr>', {
  desc = "go to buffer (backward)",
})

-- Text object for a URL
keymap.set({ "x", "o" }, "iu", "<cmd>call text_obj#URL()<cr>", { desc = "URL text object" })

-- Text object for the entire buffer
keymap.set({ "x", "o" }, "iB", ":<C-U>call text_obj#Buffer()<cr>", { desc = "buffer text object" })

-- Remove trailing whitespace. :StripTrailingWhitespace comes from
-- whitespace.nvim (Stage 11).
keymap.set(
  "n",
  "<leader><space>",
  "<cmd>StripTrailingWhitespace<cr>",
  { desc = "remove trailing space" }
)
