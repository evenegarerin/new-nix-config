-- Monitor setup and monitor-to-monitor navigation.
--
-- Required before hyprland.d/lid.lua: the generic per-output rules below have to
-- land before lid.lua disables the built in panel.

local common = require("common")

local mainMod          = common.mainMod
local monitor_defaults = common.monitor_defaults
local merge            = common.merge

for _, monitor in ipairs(hl.get_monitors()) do
    hl.monitor(merge(monitor_defaults, { output = monitor.name }))
end

hl.bind(mainMod .. " + H", hl.dsp.focus({ monitor = "-1" }), { description = "Focus monitor down" })

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.workspace.move({ monitor = "-1" }), { description = "Move focused window monitor down" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.workspace.move({ monitor = "+1" }), { description = "Move focused window monitor up" })
