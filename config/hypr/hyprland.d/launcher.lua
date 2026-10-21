-- Application launcher (walker).

local mainMod = require("common").mainMod

-- Walker hands the activation over to the elephant daemon, which has a single
-- global launch_prefix and no way to know which key opened walker. So the mode
-- is left behind in a file that elephant's prefix script reads back when it
-- launches the app, see hypr/launch-tagged and config/elephant/elephant.toml.
local mode_file = "$XDG_RUNTIME_DIR/launcher-mode"

-- opens the selected app in a workspace of its own
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("echo new-workspace > " .. mode_file .. "; walker"))

-- opens the selected app in the current workspace
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("echo normal > " .. mode_file .. "; walker"))

-- Apps launched in new-workspace mode come back tagged by the prefix script.
-- The tag is only there from window.open on -- at window.open_early the exec
-- rule has not been applied yet -- and hyprland appends a "*" to mark it as set
-- by a rule rather than by hand.
local launcher_tag = "launch-into-new-workspace"

hl.on("window.open", function(win)
    if type(win.tags) ~= "table" then return end

    local tagged = false
    for _, t in ipairs(win.tags) do
        local name = tostring(t):gsub("%*$", "")
        if name == launcher_tag then
            tagged = true
            break
        end
    end

    if not tagged then return end

    -- already alone on its workspace, nothing to hand out
    local ws = win.workspace
    if ws ~= nil and not ws.special and ws.windows <= 1 then return end

    hl.dispatch(hl.dsp.window.move({ window = win, workspace = "emptym", follow = true }))
end)
