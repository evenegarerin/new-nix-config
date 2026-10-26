-- Values and helpers shared across hyprland.lua and the hyprland.d modules.

local M = {
    mainMod             = "SUPER",
    standard_workspaces = 10,

    -- the built in laptop display
    -- might not work on all systems, have yet to find a better way
    panel               = "eDP-1",

    monitor_defaults    = {
        mode     = "preferred",
        position = "auto",
        scale    = 1,
    },
}

---------------------------------------------------------------------
-- lid
---------------------------------------------------------------------

-- The kernel knows whether the lid is shut; unlike a monitor rule that
-- knowledge survives both a config reload and a restart.
-- LID0 is the usual name, see the caveat on `panel` above.
local lid_state_path = "/proc/acpi/button/lid/LID0/state"

function M.lid_closed()
    local f = io.open(lid_state_path, "r")
    if not f then return false end
    local line = f:read("*l")
    f:close()

    return line ~= nil and line:match("closed") ~= nil
end

---------------------------------------------------------------------
-- generic state storage (survives config reloads, cleared on logout)
---------------------------------------------------------------------

local state_prefix = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr_state_"

-- returns the stored value, converted to the type of `default`
function M.read_state(name, default)
    local f = io.open(state_prefix .. name, "r")
    if not f then return default end
    local content = f:read("*l")
    f:close()
    if content == nil then return default end

    local t = type(default)
    if t == "boolean" then
        return content == "true"
    elseif t == "number" then
        return tonumber(content) or default
    else
        return content
    end
end

function M.write_state(name, value)
    local f = io.open(state_prefix .. name, "w")
    if not f then return end
    f:write(tostring(value))
    f:close()
end

---------------------------------------------------------------------
-- focus
---------------------------------------------------------------------

-- The window that was focused before the current one: the lowest focus_history_id
-- left over once the window at id 0 (`exclude`) is skipped.
function M.last_focused_window(exclude)
    local target = nil
    for _, w in ipairs(hl.get_windows()) do
        if (exclude == nil or w.address ~= exclude.address)
            and (target == nil or w.focus_history_id < target.focus_history_id) then
            target = w
        end
    end
    return target
end

-- Merges two tables into one table containing the key value pairs of both
-- in case of a key confict (both have the same key) the later on wins
function M.merge(...)
  local result = {}
  for _, t in ipairs({...}) do
    for k, v in pairs(t) do
      result[k] = v
    end
  end
  return result
end

function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("a")
    f:close()
    return content and content:match("^%s*(.-)%s*$") -- trim whitespace/newline
end

return M
