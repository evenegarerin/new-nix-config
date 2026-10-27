-- Hyprland configuration

-- `require` turns dots into slashes, so hyprland.d is not reachable as a module name;
-- put the directory itself on the search path instead
local config_dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
package.path = package.path .. ";" .. config_dir .. "/hyprland.d/?.lua"

local common = require("common")

local mainMod             = common.mainMod
local standard_workspaces = common.standard_workspaces
local read_state          = common.read_state
local write_state         = common.write_state
local last_focused_window = common.last_focused_window
local monitor_defaults    = common.monitor_defaults
local panel               = common.panel
local lid_closed          = common.lid_closed
local merge               = common.merge

require("launcher")
require("special")

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Environment
--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- cursor (see config/gtk-* and the borealis-cursors package)
hl.env("XCURSOR_THEME", "Borealis-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Borealis-cursors")
hl.env("HYPRCURSOR_SIZE", "24")

-- hyprshot save location (replaces hyprshot.nix saveLocation)
hl.env("HYPRSHOT_DIR", "$HOME/Pictures/Screenshots")

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Autostart
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlock --immediate-render --no-fade-in")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("kitty")
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("swaync")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-clip-persist")
    hl.exec_cmd("env -u HL_INITIAL_WORKSPACE_TOKEN pcmanfm --daemon-mode")
    hl.exec_cmd("walker --gapplication-service")
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Monitors
--------------------------------------------------------------------------------------------------------------------------------------------------------------

local monitors = hl.get_monitors()

for _, monitor in ipairs(monitors) do
    hl.monitor(merge(monitor_defaults, { output = monitor.name }))
end

local function other_monitor_present()
    for _, m in ipairs(monitors) do
        if m.name ~= panel then return true end
    end
    return false
end

if lid_closed() and other_monitor_present() then
    hl.monitor(merge(monitor_defaults, { output = panel, disabled = true }))
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Window rules
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.window_rule({
    match = {
        fullscreen_state_client = 1,
    },
    fullscreen_state = "0 0",
})

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Look & feel
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0
    },

    decoration = {
        rounding = 0,
        dim_special = 0,

        blur = {
            enabled = true,
            size = 2,
            passes = 1,
            new_optimizations = true,
            vibrancy = 0,
            vibrancy_darkness = 0,
            noise = 0.012,
            brightness = 0.85,
            contrast = 1.0,
            xray = false
        }
    },
    misc = {
        focus_on_activate = true,
        vrr = 0,
        disable_splash_rendering = true
    },

    input = {
        kb_layout = "de",
        numlock_by_default = true
    },

    cursor = {
        hide_on_key_press = true,
        inactive_timeout = 3
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true
    }
})

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "specialWorkspace", enabled = false })


--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Focus
--------------------------------------------------------------------------------------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Keybindings
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Launch kitty" })

hl.bind(mainMod .. " + Q", function()
    local active = hl.get_active_window()

    if active == nil then return end
    hl.dispatch(hl.dsp.window.close())
end, { description = "Close active window" })

-- jump back to the window focused before the current one
hl.bind(mainMod .. " + U", function()
    local target = last_focused_window(hl.get_active_window())

    if target == nil then return end
    hl.dispatch(hl.dsp.focus({ window = target }))
end, { description = "Focus last active window" })

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock --grace 3"), { description = "Activate lockscreen" })

-- screenshot (hyprshot)
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"), { description = "Take a regioned screenshot" })
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m output"), { description = "Take a fullscreen screenshot" })

-- media / function keys
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume 0 -10%"), { description = "Decrease output volume" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume 0 +10%"), { description = "Increase output volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl -- set-sink-mute 0 toggle"), { description = "Toggle output mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl -- set-source-mute 0 toggle"), { description = "Toggle input mute" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { description = "Decrease monitor brightness" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +10%"), { description = "Increase monitor brightness" })

hl.bind("XF86PickupPhone", hl.dsp.exec_cmd("playerctl play"), { description = "Media Player play" })
hl.bind("XF86HangupPhone", hl.dsp.exec_cmd("playerctl -a pause"), { description = "Media Player pause" })

hl.bind("F1", hl.dsp.exec_cmd("playerctl --player=playerctld play-pause"), { description = "Media Player toggle play" })

hl.bind(mainMod .. " + J", hl.dsp.focus({ workspace = "m-1" }), { description = "Focus ws down" })
hl.bind(mainMod .. " + K", function()
    local current = hl.get_active_workspace()

    if current ~= nil and not current.special and current.windows > 0 and current.id
 < standard_workspaces then
        local is_last = true

        for _, w in ipairs(hl.get_workspaces()) do
            if not w.special and w.monitor == current.monitor and w.id > current.id
then
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

hl.bind(mainMod .. " + H", hl.dsp.focus({ monitor = "-1" }), { description = "Focus monitor down" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ monitor = "+1" }), { description = "Focus monitor up" })

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.workspace.move({ monitor = "-1" }), { description = "Move focused window monitor down" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.workspace.move({ monitor = "+1" }), { description = "Move focused window monitor up" })

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

  if active then hl.dispatch(hl.dsp.focus({ window = active })) end
end, { description = "Rearrange windows in current ws" })

for i = 1, standard_workspaces do
    local key = i % standard_workspaces -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Move to ws " .. key })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), { description = "Move focused window to ws " .. key })
end

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Toggle resize submap" })

local gaps_in_normal  = 2
local gaps_out_normal = 4
local rounding_normal = 10

local function apply_layout(state)
    if state then
        hl.config({
            general = { gaps_in = 0, gaps_out = 0 },
            decoration = { rounding = 0 }
        })
    else
        hl.config({
            general = { gaps_in = gaps_in_normal, gaps_out = gaps_out_normal },
            decoration = { rounding = rounding_normal }
        })
    end
end

local function set_fullscreen(state)
    local active_state = read_state("fullscreen", false)

    if state ~= active_state then
        hl.dispatch(hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))

        write_state("fullscreen", state)
        apply_layout(state)
    end
end

hl.on("hyprland.start", function()
    write_state("fullscreen", true)
end)

apply_layout(read_state("fullscreen", true))

hl.bind(mainMod .. " + F", function()
    set_fullscreen(not read_state("fullscreen", false))
end, { description = "Toggle fake fullscreen for entire system" })

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle true fullscreen for current window" })

hl.bind(mainMod .. " + SHIFT + ssharp", hl.dsp.exec_cmd([[
hyprctl binds -j |
  jq -r 'def getbit($position; $n):
    fmod($n/($position|exp2)|floor;2) | fabs;

def mod($position; $name):
    if getbit($position; .modmask) == 1 then $name + " + " else "" end;

.[] | .description + "|" + mod(6; "SUPER") + mod(2; "Ctrl") + mod(3; "Alt") + mod(0; "Shift") + .key
' | column -t -s "|" |
  rofi -dmenu -i -sync -p "Bind" -format e -case-smart -l 40 -theme-str "window {width: 90%;} listview {columns: 4; scrollbar: false;}"
]]), { description = "Show keybind cheatsheet" })

-- handle laptop monitor close and open
-- (the matching rule for a reload while the lid is shut lives in the Monitors section)

hl.bind("switch:on:Lid Switch", function()
  if #(hl.get_monitors()) <= 1 then
    hl.exec_cmd("hyprlock --immediate-render")

    return
  end

  hl.monitor(merge(monitor_defaults, { output = panel, disabled = true }))
end, { description = "Turn of monitor on lid close" })

hl.bind("switch:off:Lid Switch", function()
  set_fullscreen(true)

  hl.monitor(merge(monitor_defaults, { output = panel, disabled = false }))
end, { description = "Turn on monitor on lid open" })

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resize submap
--------------------------------------------------------------------------------------------------------------------------------------------------------------


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