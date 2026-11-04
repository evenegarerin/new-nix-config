-- Virtual Mouse submap: SUPER+SHIFT+M enters a mode where hjkl moves the mouse.

local mainMod = require("common").mainMod

hl.bind(mainMod .. " + SHIFT + M", hl.dsp.submap("virtual-mouse"), { description = "Toggle virtual mouse submap" })

local step = 20 -- pixels per tick
local fastStep = 80 -- pixels per tick with SHIFT held

local dirs = {
	H = { -1, 0, "left" },
	J = { 0, 1, "down" },
	K = { 0, -1, "up" },
	L = { 1, 0, "right" },
}

hl.define_submap("virtual-mouse", function()
	for key, d in pairs(dirs) do
		hl.bind(
			key,
			hl.dsp.exec_cmd(string.format("wlrctl pointer move %d %d", d[1] * step, d[2] * step)),
			{ repeating = true, description = "Virtual mouse: move " .. d[3] }
		)
		hl.bind(
			"SHIFT + " .. key,
			hl.dsp.exec_cmd(string.format("wlrctl pointer move %d %d", d[1] * fastStep, d[2] * fastStep)),
			{ repeating = true, description = "Virtual mouse: move " .. d[3] .. " (fast)" }
		)
	end

	hl.bind("RETURN", hl.dsp.exec_cmd("wlrctl pointer click left"), { description = "Virtual mouse: left click" })

	-- Use `reset` to go back to the global submap
	hl.bind("escape", hl.dsp.submap("reset"), { description = "Active in virtual-mouse submap, exit submap" })
	hl.bind("R", hl.dsp.submap("reset"), { description = "Active in virtual-mouse submap, exit submap" })

	-- broken in current hyprland version as catchall does also trigger on the resizing keys
	-- hl.bind("catchall", hl.dsp.submap("reset"))
end)

hl.on("keybinds.submap", function(name)
	local inMouseMode = (name == "virtual-mouse")

	hl.config({
		general = { col = { active_border = inMouseMode and 0xff3292ff or 0xffffffff } },
		cursor = { hide_on_key_press = not inMouseMode },
	})
end)
