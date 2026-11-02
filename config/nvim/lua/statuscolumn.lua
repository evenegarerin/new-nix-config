local M = {}

local api = vim.api

local SEPARATOR = "%#StatusColumnSeparator#" .. require("symbol_icon").fillchars.vert .. "%*"

-- Builtin items only, so this can never be the thing that throws. `%l` honours
-- `number`/`relativenumber` on its own.
local FALLBACK = "%s%=%l" .. SEPARATOR

--- The format string `statuscolumn` is set to, shared with `options.lua` and the
--- `statuscolumn_restore` autocmd in `custom-autocmd.lua`.
M.FORMAT = "%{%v:lua.require'statuscolumn'.render()%}"

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

  -- Both fields come from a third party's extmark, so neither is trusted: a
  -- non-string `sign_text` would throw, and an empty group name renders as `%##`,
  -- which errors with E5248.
  local text = type(detail.sign_text) == "string" and vim.trim(detail.sign_text) or ""
  local pad = math.max(0, width - api.nvim_strwidth(text))

  local hl = detail.sign_hl_group
  if type(hl) ~= "string" or hl == "" then
    hl = "SignColumn"
  end

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
    return "%=" .. string.rep(" ", 2) .. SEPARATOR
  end

  local n = vim.v.lnum
  if vim.wo.relativenumber and vim.v.relnum > 0 then
    n = vim.v.relnum
  end

  return "%=" .. n .. SEPARATOR
end

--- The real renderer. May throw -- only `M.render` is safe to hand to the redraw loop.
--- @return string
local function render()
  if vim.bo.buftype ~= "" then
    return "%s" .. number()
  end

  local git, other = slots()
  return git .. other .. number()
end

local reported = false

--- @return string
function M.render()
  local ok, result = pcall(render)
  if ok then
    return result
  end

  -- Never let an error reach the redraw loop: Neovim answers by clearing this
  -- window's `statuscolumn` for the rest of the session, and every window split off
  -- it inherits the empty value. The gutter then silently reverts to the builtin
  -- one, losing the separator and the sign cells with no hint as to why.
  if not reported then
    reported = true
    vim.schedule(function()
      vim.notify("statuscolumn: " .. tostring(result), vim.log.levels.ERROR)
    end)
  end

  return FALLBACK
end

return M
