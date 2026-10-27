local mainMod = require("common").mainMod

local M = {}

-- Utility apps toggle over the current workspace on one shared special workspace
-- instead of getting a workspace of their own (see hyprland.d/launcher.lua).
local special_ws = "utils"

-- add utility apps here:
--   exec  label for the generated window rule, no matching happens on it
--   class hyprland regex, matched against the window class (see `hyprctl clients`)
local utility_apps = {
    { exec = "gnome-calculator", class = [[^org\.gnome\.Calculator$]] }, 
    { exec = "devtoolbox", class = [[^me\.iepure\.devtoolbox$]]},
    { exec = "chromium", class = [[^chromium\-browser$]]},
}

local function to_lua_pattern(re)
    return (re:gsub("\\(.)", "%%%1"))
end

function M.matches_utility_app(str)
    for _, app in ipairs(utility_apps) do
        if str:match(to_lua_pattern(app.class)) then
            return app  -- or return true
        end
    end
    return nil
end

-- utility windows are overlays wherever they end up
for _, app in ipairs(utility_apps) do
    hl.window_rule({
        name      = "utility-" .. app.exec,
        match     = { class = app.class },
        workspace = "special:" .. special_ws,
        float     = true,
        size      = "50% 50%",
        center    = true,
    })
end

hl.window_rule({
  match = { class = [[^chromium\-browser$]] },
  size  = { "monitor_w * 0.8", "monitor_h * 0.8" },
})

hl.bind(mainMod .. " + Z", hl.dsp.workspace.toggle_special(special_ws), { description = "Toggle special ws" })

hl.bind(mainMod .. " + SHIFT + Z", function()
    local w = hl.get_active_window()
    local ws = hl.get_active_workspace()
    local sws = hl.get_active_special_workspace()

    if (w == nil) then return end
    if (ws == nil) then return end

    if (sws and sws.name == "special:" .. special_ws) then
        hl.dispatch(hl.dsp.window.move({ window = w, workspace = ws, follow = true }))
        hl.dispatch(hl.dsp.window.float({ window = w, action = "unset" }))
    else
        hl.dispatch(hl.dsp.window.float({ window = w, action = "set" }))
        hl.dispatch(hl.dsp.window.center({ window = w }))
        hl.dispatch(hl.dsp.window.move({ window = w, workspace = "special:" .. special_ws }))
    end
end, { description = "Moves current window into/out of special ws" })

hl.on("window.open_early", function(w)
    if not w or not w.workspace or not w.class then return end
    if w.workspace.name ~= "special:" .. special_ws then return end
    if M.matches_utility_app(w.class) then return end

    local ws = hl.get_active_workspace()
    if ws then
        hl.dispatch(hl.dsp.window.move({ window = w, workspace = ws }))
    end
end)

return M