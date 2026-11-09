-- Screenshots (hyprshot).

local mainMod = require("hyprland.common").mainMod

-- save location (replaces hyprshot.nix saveLocation)
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")

hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"), { description = "Take a fullscreen screenshot" })
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region"), { description = "Take a regioned screenshot" })

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("hyprshot -m output"), { description = "Take a fullscreen screenshot" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"), { description = "Take a regioned screenshot" })
