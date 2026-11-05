-- Submaps: SUPER+R resizes the active window with hjkl,
-- SUPER+SHIFT+M moves the mouse with hjkl.

local mainMod = require("common").mainMod

local defaultBorder = 0xffffffff
local submapBorders = {
  resize = 0xffff0000,
  ["virtual-mouse"] = 0xff3292ff,
}

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Toggle resize submap" })

hl.define_submap("resize", function()
  -- Set repeating binds for resizing the active window.
  hl.bind(
    "J",
    hl.dsp.window.resize({ x = 0, y = -10, relative = true }),
    { repeating = true, description = "Resize submap: move split up" }
  )
  hl.bind(
    "K",
    hl.dsp.window.resize({ x = 0, y = 10, relative = true }),
    { repeating = true, description = "Resize submap: move split down" }
  )
  hl.bind(
    "H",
    hl.dsp.window.resize({ x = -18, y = 0, relative = true }),
    { repeating = true, description = "Resize submap: move split left" }
  )
  hl.bind(
    "L",
    hl.dsp.window.resize({ x = 18, y = 0, relative = true }),
    { repeating = true, description = "Resize submap: move split right" }
  )

  -- Use `reset` to go back to the global submap
  hl.bind("escape", hl.dsp.submap("reset"), { description = "Active in resize submap, exit submap" })
  hl.bind("R", hl.dsp.submap("reset"), { description = "Active in resize submap, exit submap" })

  -- broken in current hyprland version as catchall does also trigger on the resizing keys
  -- hl.bind("catchall", hl.dsp.submap("reset"))
end)

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
  hl.config({
    general = { col = { active_border = submapBorders[name] or defaultBorder } },
    cursor = { hide_on_key_press = name ~= "virtual-mouse" },
  })
end)
