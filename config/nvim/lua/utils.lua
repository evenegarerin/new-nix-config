-- Shared helpers. Only the functions needed by the currently-enabled modules
-- live here; the rest are pulled over from ../../nvim.bak/lua/utils.lua as the
-- stages that use them land (see README.md).
local M = {}

--- Check whether an executable is available on PATH.
--- @param name string
--- @return boolean
function M.executable(name)
  if vim.fn.executable(name) > 0 then
    return true
  end

  return false
end

--- Wrapper around vim.fn.has() returning a boolean.
--- @param feat string
--- @return boolean
function M.has(feat)
  if vim.fn.has(feat) == 1 then
    return true
  end

  return false
end

--- Create a directory if it does not already exist.
--- @param dir string
function M.may_create_dir(dir)
  local res = vim.fn.isdirectory(dir)

  if res == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

return M
