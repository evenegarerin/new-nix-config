-- Hyprland configuration

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
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("kitty")
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("swaync")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-clip-persist")
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

hl.on("window.open", function(w)
    if w == nil then return end

    local windows = hl.get_workspace_windows(w.workspace)

    if #windows == 0 or (#windows == 1 and windows[1] == w) then
        hl.dispatch(hl.dsp.window.fullscreen_state({
            window = w,
            action = "set",
            internal = 2,
            client = -1,
        }))
    end
end)

hl.on("window.close", function(w)
    if w == nil then return end

    local windows = hl.get_workspace_windows(w.workspace)

    if #windows == 2 then
        for _, window in ipairs(windows) do
            if window ~= w then
                hl.dispatch(hl.dsp.window.fullscreen_state({
                    window = window,
                    action = "set",
                    internal = 2,
                    client = -1,
                }))

                hl.dispatch(hl.dsp.focus({window = window }))
                break
            end
        end
    end
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Look & feel
--------------------------------------------------------------------------------------------------------------------------------------------------------------

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 6
    },

    decoration = {
        rounding = 10
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
-- Keybindings
--------------------------------------------------------------------------------------------------------------------------------------------------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("bash ~/.config/wofi/wofi-into-empty-workspace.sh"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("wofi"))

hl.bind(mainMod .. " + Q",
    hl.dsp.exec_cmd(
        "if [ $(hyprctl activeworkspace -j | jq -r .windows) -le 1 ]; then hyprctl dispatch 'hl.dsp.window.close()'; hyprctl dispatch 'hl.dsp.focus({ workspace = \"previous\" })'; else hyprctl dispatch 'hl.dsp.window.close()'; fi"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
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

-- lock on lid close, only if there are no other monitors connected
hl.bind("switch:on:Lid Switch",
    hl.dsp.exec_cmd("sh -c '[ $(hyprctl -j monitors | jq length) -eq 1 ] && hyprlock --immediate-render'"))

hl.bind(mainMod .. " + J", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ workspace = "m+1" }))

hl.bind(mainMod .. " + SHIFT + J", hl.dsp.workspace.move({ monitor = "-1" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.workspace.move({ monitor = "+1" }))

hl.bind(mainMod .. " + H", hl.dsp.window.cycle_next())

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

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
end)
