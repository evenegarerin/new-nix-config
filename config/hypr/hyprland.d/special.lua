local mainMod = require("common").mainMod

-- Utility apps toggle over the current workspace on one shared special workspace
-- instead of getting a workspace of their own (see hyprland.d/launcher.lua).
local special_ws = "utils"

-- add utility apps here:
--   exec  label for the generated window rule, no matching happens on it
--   class hyprland regex, matched against the window class (see `hyprctl clients`)
local utility_apps = {
    { exec = "gnome-calculator", class = [[^org\.gnome\.Calculator$]] },
    { exec = "devtoolbox", class = [[^me\.iepure\.devtoolbox]]},
    { exec = "chromium", class = [[^chromium\-browser]]},
}

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

hl.bind(mainMod .. " + Z", function()
    hl.dispatch(hl.dsp.workspace.toggle_special(special_ws))
    hl.dispatch(hl.dsp.window.cycle_next())
end)