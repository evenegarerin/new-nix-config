-- Window focus: follow the focus history and move around within a workspace.

local common = require("hyprland.common")

local mainMod             = common.mainMod
local last_focused_window = common.last_focused_window

-- When the focused window goes away, follow the focus history to the last window
hl.on("window.close", function(win)
    if not win.active then return end

    local ws = hl.get_active_workspace()

    if ws.windows > 1 then return end

    -- the closing window is still listed here and still holds id 0
    local target = last_focused_window(win)
    if target == nil then return end

    hl.dispatch(hl.dsp.focus({ window = target }))
end)

-- jump back to the window focused before the current one
hl.bind(mainMod .. " + U", function()
    local target = last_focused_window(hl.get_active_window())

    if target == nil then return end
    hl.dispatch(hl.dsp.focus({ window = target }))
end, { description = "Focus last active window" })

hl.bind(mainMod .. " + N", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Focus next window in current ws" })
hl.bind(mainMod .. " + SHIFT + N", function()
  local active = hl.get_active_window()
  if active == nil then return end

  local wins = {}
  for _, w in ipairs(hl.get_windows({ workspace = hl.get_active_workspace() })) do
    if not w.floating then table.insert(wins, w) end
  end
  local n = #wins
  if n < 2 then return end

  -- last window swaps its way through all others = one rotation step
  for i = n - 1, 1, -1 do
    hl.dispatch(hl.dsp.focus({ window = wins[n] }))
    hl.dispatch(hl.dsp.window.swap({ window = wins[n], target = wins[i] }))
  end

  hl.dispatch(hl.dsp.focus({ window = active }))
end, { description = "Rearrange windows in current ws" })
