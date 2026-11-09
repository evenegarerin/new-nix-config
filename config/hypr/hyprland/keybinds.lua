-- Keybinds that do not belong to a feature module of their own:
-- terminal, window close, lockscreen and the bind cheatsheet.

local mainMod = require("hyprland.common").mainMod

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Launch kitty" })

hl.bind(mainMod .. " + Q", function()
  local active = hl.get_active_window()

  if active == nil then
    return
  end
  hl.dispatch(hl.dsp.window.close())
end, { description = "Close active window" })

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock --grace 3"), { description = "Activate lockscreen" })

local show_binds = hl.dsp.exec_cmd([[
hyprctl binds -j |
  jq -r 'def getbit($position; $n):
    fmod($n/($position|exp2)|floor;2) | fabs;

def mod($position; $name):
    if getbit($position; .modmask) == 1 then $name + " + " else "" end;

.[] | .description + "|" + mod(6; "SUPER") + mod(2; "Ctrl") + mod(3; "Alt") + mod(0; "Shift") + .key
' | column -t -s "|" |
  rofi -dmenu -i -sync -p "Bind" -format e -case-smart -l 40 -theme-str "window {width: 90%;} listview {columns: 4; scrollbar: false;}"
]])

hl.bind(mainMod .. " + SHIFT + ssharp", show_binds, { description = "Show keybind cheatsheet (de layout)" })
hl.bind(mainMod .. " + SHIFT + slash", show_binds, { description = "Show keybind cheatsheet (us layout)" })

local function zoom(delta)
  local current = hl.get_config("cursor.zoom_factor")
  local new = math.max(1, math.min(5, current + delta))
  hl.config({ cursor = { zoom_factor = new } })
end

hl.bind(mainMod .. " + mouse_down", function()
  zoom(-0.5)
end)
hl.bind(mainMod .. " + mouse_up", function()
  zoom(0.5)
end)
