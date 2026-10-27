-- Application launcher (walker).

local common = require("common")

local mainMod = common.mainMod
local read_file = common.read_file

local matches_utility_app = require("special").matches_utility_app

local runtime_dir = os.getenv("XDG_RUNTIME_DIR")
local mode_file = runtime_dir .. "/launcher-mode"

-- opens the selected app in a workspace of its own
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("echo new-workspace > " .. mode_file .. "; walker"), { description = "App Launcher, launch into new ws" })

-- opens the selected app in the current workspace
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("echo normal > " .. mode_file .. "; walker"), { description = "App Launcher, launch into current ws" })

-- clipboard history, served by elephant's clipboard provider. no mode_file here:
-- that only steers app launches into a new workspace.
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("walker -m clipboard"), { description = "Clipboard history" })

hl.layer_rule({
    match = { namespace = "walker" },
    blur = true,
    ignore_alpha = 0.1,
    no_anim = true
})

local function reset_mode_file()
    local f = io.open(mode_file, "w")
    if f then f:write("normal"); f:close() end
end

hl.on("window.open", function(w)
    if not w.class then return end
    
    if (matches_utility_app(w.class)) then
        reset_mode_file()
        return
    end
    
    local mode = read_file(mode_file)
    
    if mode == "new-workspace-confirm" then
        reset_mode_file()
        
        hl.dispatch(hl.dsp.window.move({ window = w, workspace = "emptym" }))
    end
end)