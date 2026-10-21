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

require("launcher")

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
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Monitors
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Window rules
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.window_rule({
    match = {
        fullscreen_state_client = 1,
    },
    fullscreen_state = "0 0",
})

-- Utility apps toggle over the current workspace on one shared special workspace
-- instead of getting a workspace of their own (see hyprland.d/launcher.lua).
local special_ws = "utils"

-- add utility apps here:
--   exec  label for the generated window rule, no matching happens on it
--   class hyprland regex, matched against the window class (see `hyprctl clients`)
local utility_apps = {
    { exec = "gnome%-calculator", class = [[^org\.gnome\.Calculator$]] },
}

-- utility windows are overlays wherever they end up
for _, app in ipairs(utility_apps) do
    hl.window_rule({
        name   = "utility-" .. app.exec,
        match  = { class = app.class },
        float  = true,
        size   = "50% 50%",
        center = true,
    })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Look & feel
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0
    },

    decoration = {
        rounding = 0
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

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))

hl.bind(mainMod .. " + Q", function()
    local active = hl.get_active_window()

    if active == nil then return end
    hl.dispatch(hl.dsp.window.close())
end)

-- jump back to the window focused before the current one
hl.bind(mainMod .. " + U", function()
    local target = last_focused_window(hl.get_active_window())

    if target == nil then return end
    hl.dispatch(hl.dsp.focus({ window = target }))
end)

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock --grace 3"))
hl.bind(mainMod .. " + N",
    hl.dsp.exec_cmd(
        "sh -c 'out=$(hyprctl dispatch swapwindow r 2>&1); echo \"$out\" | grep -qx \"ok\" || hyprctl dispatch swapwindow l'"))

-- screenshot (hyprshot)
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m output"))

-- media / function keys
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume 0 -10%"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume 0 +10%"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl -- set-sink-mute 0 toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl -- set-source-mute 0 toggle"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +10%"))

hl.bind("XF86PickupPhone", hl.dsp.exec_cmd("playerctl play"))
hl.bind("XF86HangupPhone", hl.dsp.exec_cmd("playerctl -a pause"))

hl.bind("F1", hl.dsp.exec_cmd("playerctl --player=playerctld play-pause"))

hl.bind(mainMod .. " + J", hl.dsp.focus({ workspace = "m-1" }))
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
end)

hl.bind(mainMod .. " + H", hl.dsp.focus({ monitor = "-1" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ monitor = "+1" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.workspace.move({ monitor = "-1" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.workspace.move({ monitor = "+1" }))

hl.bind(mainMod .. " + N", hl.dsp.window.cycle_next())
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
end)

for i = 1, standard_workspaces do
    local key = i % standard_workspaces -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

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

hl.bind(mainMod .. " + F", function()
    set_fullscreen(not read_state("fullscreen", false))
end)

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- handle laptop monitor close and open

local panel = "eDP-1" -- might not work on all system, have yet to find a better way

hl.bind("switch:on:Lid Switch", function()
  if #(hl.get_monitors()) <= 1 then
    hl.exec_cmd("hyprlock --immediate-render")

    return
  end

  hl.monitor({ output = panel, disabled = true })
end)

hl.bind("switch:off:Lid Switch", function()
  set_fullscreen(true)

  hl.monitor({ output = panel, disabled = false, mode = "preferred", position = "auto", scale = 1 })
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resize submap
--------------------------------------------------------------------------------------------------------------------------------------------------------------


hl.define_submap("resize", function()
    -- Set repeating binds for resizing the active window.
    hl.bind("J", hl.dsp.window.resize({ x = -18, y = 0, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 18, y = 0, relative = true }), { repeating = true })
    hl.bind("H", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })

    -- Use `reset` to go back to the global submap
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("R", hl.dsp.submap("reset"))
    
    -- broken in current hyprland version as catchall does also trigger on the resizing keys
    -- hl.bind("catchall", hl.dsp.submap("reset"))
end)

