-- Workspace navigation.

local common = require("hyprland.common")

local mainMod = common.mainMod
local standard_workspaces = common.standard_workspaces

hl.bind(mainMod .. " + J", hl.dsp.focus({ workspace = "m-1" }), { description = "Focus ws down" })
hl.bind(mainMod .. " + K", function()
  local current = hl.get_active_workspace()

  if current ~= nil and not current.special and current.windows > 0 and current.id < standard_workspaces then
    local is_last = true

    for _, w in ipairs(hl.get_workspaces()) do
      if not w.special and w.monitor == current.monitor and w.id > current.id then
        is_last = false
        break
      end
    end

    if is_last then
      hl.dispatch(hl.dsp.focus({ workspace = current.id + 1 }))
      return
    end
  end

  hl.dispatch(hl.dsp.focus({ workspace = "m+1" }))
end, { description = "Focus ws up" })

for i = 1, standard_workspaces do
  local key = i % standard_workspaces -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Move to ws " .. key })
  hl.bind(
    mainMod .. " + SHIFT + " .. key,
    hl.dsp.window.move({ workspace = i, follow = false }),
    { description = "Move focused window to ws " .. key }
  )
end
