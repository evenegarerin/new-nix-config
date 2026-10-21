-- Application launcher (wofi).

local mainMod = require("common").mainMod

-- opens an app selected via wofi into its own workspace
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd([==[bash -c '
selected_app=$(wofi --show drun -a -i -D drun-print_command=true)

if [[ -n "$selected_app" ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = \"emptym\" })"
    hyprctl dispatch "hl.dsp.exec_cmd(\"$selected_app\")"
fi
']==]))

hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("bash -c 'wofi --show drun -a -i'"))
