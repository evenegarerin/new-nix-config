-- A hand-rolled `'statuscolumn'` whose only job is to give gitsigns a slot of
-- its own.
--
-- Why this exists: the native sign column cannot reserve a slot. `%s` packs
-- signs to the left and `'signcolumn'` only caps how many fit, so with
-- `yes:2` a line carrying a diagnostic but no git change puts the diagnostic
-- in the first cell. Sign priority decides the *order* signs are drawn in, not
-- which cell they land in, so no combination of priorities fixes that.
--
-- Here the two cells are explicit. Slot 1 renders gitsigns and nothing else,
-- blank when the line is unchanged. Slot 2 renders everything else
-- (diagnostics, nvim-lightbulb), highest priority first. Then the line number.
--
-- Setting `'statuscolumn'` replaces the whole gutter, so the number column is
-- rendered here too -- including `relativenumber`, which `custom-autocmd.lua`
-- toggles per window.

local M = {}

local api = vim.api

-- Resolved on first use: gitsigns loads at `VeryLazy`, so its namespaces do
-- not exist while the first buffer is drawn.
--
-- There is more than one -- `gitsigns_signs_` holds the unstaged signs and
-- gitsigns adds further namespaces for staged signs and blame -- so this
-- collects every id whose name starts with `gitsigns`, rather than picking the
-- first match out of `pairs()`, whose order is not defined.
local git_ns = nil

local function gitsigns_ns()
  if git_ns then
    return git_ns
  end

  local found = {}
  local any = false

  for name, ns in pairs(api.nvim_get_namespaces()) do
    if vim.startswith(name, "gitsigns") then
      found[ns] = true
      any = true
    end
  end

  if any then
    git_ns = found
  end

  return git_ns
end

-- Cell budget per slot. Git signs (`+ ~ _ ‾ │`) are one cell wide; the
-- diagnostic and lightbulb icons are emoji and take two. Both slots are padded
-- to a fixed width or the line number shifts sideways depending on what
-- happens to be on the line.
local GIT_WIDTH = 1
local OTHER_WIDTH = 2

--- One sign as a statusline chunk, padded to `width` cells and carrying its
--- own highlight group.
--- @param detail table|nil extmark details with `sign_text`, or nil for a blank
--- @param width integer
--- @return string
local function chunk(detail, width)
  if not detail then
    return string.rep(" ", width)
  end

  local text = vim.trim(detail.sign_text)
  local pad = math.max(0, width - vim.fn.strdisplaywidth(text))
  local hl = detail.sign_hl_group or "SignColumn"

  return table.concat { "%#", hl, "#", text, "%*", string.rep(" ", pad) }
end

--- The two gutter cells for the line being drawn.
--- @return string git, string other -- each exactly one cell wide
local function slots()
  local git, other = nil, nil

  local lnum = vim.v.lnum - 1
  local ok, marks = pcall(
    api.nvim_buf_get_extmarks,
    0,
    -1, -- every namespace; `ns_id` comes back in the details
    { lnum, 0 },
    { lnum, -1 },
    { details = true, type = "sign" }
  )

  if ok then
    local gns = gitsigns_ns()
    local best = -math.huge

    for _, mark in ipairs(marks) do
      local detail = mark[4]

      if detail.sign_text then
        if gns and gns[detail.ns_id] then
          git = detail
        elseif (detail.priority or 0) > best then
          best = detail.priority or 0
          other = detail
        end
      end
    end
  end

  return chunk(git, GIT_WIDTH), chunk(other, OTHER_WIDTH)
end

--- @return string
local function number()
  if not vim.wo.number then
    return ""
  end

  -- a soft-wrapped continuation row: keep the width, drop the digits
  if vim.v.virtnum ~= 0 then
    return "%=" .. string.rep(" ", 2) .. " "
  end

  local n = vim.v.lnum
  if vim.wo.relativenumber and vim.v.relnum > 0 then
    n = vim.v.relnum
  end

  return "%=" .. n .. " "
end

--- @return string
function M.render()
  -- Special windows (nvim-tree, quickfix, help, terminal) keep whatever gutter
  -- they set for themselves; only the number part applies there.
  if vim.bo.buftype ~= "" then
    return number()
  end

  local git, other = slots()
  return git .. other .. number()
end

return M
