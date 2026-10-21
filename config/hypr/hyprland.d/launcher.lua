-- Application launcher (walker).

local mainMod = require("common").mainMod

local mode_file = "$XDG_RUNTIME_DIR/launcher-mode"

-- opens the selected app in a workspace of its own
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("echo new-workspace > " .. mode_file .. "; walker"))

-- opens the selected app in the current workspace
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("echo normal > " .. mode_file .. "; walker"))

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
