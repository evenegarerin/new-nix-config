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

--- Whether cwd is inside a git work tree. Fires the custom `User InGitRepo`
--- event as a side effect -- the Stage 9 git plugins lazy-load on it.
--- @return boolean
function M.inside_git_repo()
  local result = vim.system({ "git", "rev-parse", "--is-inside-work-tree" }, { text = true })
    :wait()
  if result.code ~= 0 then
    return false
  end

  vim.cmd([[doautocmd User InGitRepo]])

  return true
end

--- Size of a file in bytes, or nil if it cannot be stat'ed.
--- @param fpath string
--- @return integer|nil
function M.filesize(fpath)
  local stat = vim.uv.fs_stat(fpath)

  if stat then
    return stat.size
  end

  return nil
end

--- Move `ele` to the front of `items`, leaving the rest in order.
--- @param items string[]
--- @param ele string|nil
--- @return string[]
function M.reorder_list_element(items, ele)
  if not vim.list_contains(items, ele) then
    return items
  end

  local new_items = { ele }
  for _, v in ipairs(items) do
    if v ~= ele then
      table.insert(new_items, v)
    end
  end

  return new_items
end

--- @param is_local boolean local branches if true, remote-tracking if false
--- @return string[]
function M._get_branch(is_local)
  local git_cmd
  if is_local then
    git_cmd = { "git", "branch", "--list", "--format=%(refname:short)" }
  else
    git_cmd = {
      "git",
      "for-each-ref",
      "--exclude=refs/remotes/*/HEAD",
      "--format=%(refname:short)",
      "refs/remotes/",
    }
  end

  local result = vim.system(git_cmd, { text = true }):wait()
  if result.code ~= 0 then
    return {}
  end

  return vim.split(result.stdout, "\n", { trimempty = true })
end

--- @return table<string, string[]> keys: "local", "remote"
function M.get_git_branches()
  return {
    ["local"] = M._get_branch(true),
    remote = M._get_branch(false),
  }
end

return M
