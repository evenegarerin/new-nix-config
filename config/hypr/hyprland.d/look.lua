-- Look & feel: global appearance, input and animation settings.
--
-- Note: the gaps/rounding values here are the fullscreen-layout defaults;
-- hyprland.d/fullscreen.lua overrides them at load, so it must be required later.

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
        disable_splash_rendering = true,

        force_default_wallpaper = 0,
        disable_hyprland_logo = true
    },

    input = {
        kb_layout = "us",
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

-- hyprpaper re-creates its layer surfaces whenever the output set changes (e.g.
-- the panel being disabled on lid close). Without this the wallpaper on the
-- remaining monitor slides back in, since the default layer animation is `slide`.
hl.layer_rule({
    match = { namespace = "hyprpaper" },
    no_anim = true
})
