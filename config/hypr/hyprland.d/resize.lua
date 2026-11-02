-- Resize submap: SUPER+R enters a mode where hjkl resize the active window.

local mainMod = require("common").mainMod

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Toggle resize submap" })

hl.define_submap("resize", function()
    -- Set repeating binds for resizing the active window.
    hl.bind("J", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true, description = "Resize submap: move split up" })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true, description = "Resize submap: move split down" })
    hl.bind("H", hl.dsp.window.resize({ x = -18, y = 0, relative = true }), { repeating = true, description = "Resize submap: move split left" })
    hl.bind("L", hl.dsp.window.resize({ x = 18, y = 0, relative = true }), { repeating = true, description = "Resize submap: move split right" })

    -- Use `reset` to go back to the global submap
    hl.bind("escape", hl.dsp.submap("reset"), { description = "Active in resize submap, exit submap" })
    hl.bind("R", hl.dsp.submap("reset"), { description = "Active in resize submap, exit submap" })
    
    -- broken in current hyprland version as catchall does also trigger on the resizing keys
    -- hl.bind("catchall", hl.dsp.submap("reset"))
end)

hl.on("keybinds.submap", function(name)
    local color;

    if (name == "resize") then
        color = 0xffff0000
    else
        color = 0xffffffff
    end

    hl.config({ general = { col = { active_border = color } } })
end)
