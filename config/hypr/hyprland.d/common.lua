-- Values and helpers shared across hyprland.lua and the hyprland.d modules.

local M = {
    mainMod             = "SUPER",
    standard_workspaces = 10,
}

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

return M
