-- Application launcher (walker).

local mainMod = require("common").mainMod

local mode_file = "$XDG_RUNTIME_DIR/launcher-mode"

-- opens the selected app in a workspace of its own
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("echo new-workspace > " .. mode_file .. "; walker"))

-- opens the selected app in the current workspace
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("echo normal > " .. mode_file .. "; walker"))
