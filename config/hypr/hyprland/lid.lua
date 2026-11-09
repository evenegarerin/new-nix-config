-- Laptop lid handling: disable the built in panel while the lid is shut.

local common = require("hyprland.common")

local monitor_defaults = common.monitor_defaults
local panel = common.panel
local lid_closed = common.lid_closed
local merge = common.merge

local monitors = hl.get_monitors()

local function other_monitor_present()
  for _, m in ipairs(monitors) do
    if m.name ~= panel then
      return true
    end
  end
  return false
end

if lid_closed() and other_monitor_present() then
  hl.monitor(merge(monitor_defaults, { output = panel, disabled = true }))
end

-- handle laptop monitor close and open
-- (the rule above covers a reload that happens while the lid is already shut)

hl.bind("switch:on:Lid Switch", function()
  if #(hl.get_monitors()) <= 1 then
    hl.exec_cmd("hyprlock --immediate-render")

    return
  end

  hl.monitor(merge(monitor_defaults, { output = panel, disabled = true }))
end, { description = "Turn off monitor on lid close" })

hl.bind("switch:off:Lid Switch", function()
  hl.monitor(merge(monitor_defaults, { output = panel, disabled = false }))
end, { description = "Turn on monitor on lid open" })
