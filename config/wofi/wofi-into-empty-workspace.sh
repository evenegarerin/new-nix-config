#!/usr/bin/env bash

# Use wofi to select an app from the "drun" menu (all installed apps)
selected_app=$(wofi --show drun -a -i)

# apps that cant be launched into a gui still open a new workspace
# might be nice to find a workaround for that at some point

# Only proceed if something was selected
if [[ -n "$selected_app" ]]; then
    # Switch to empty workspace first
    hyprctl dispatch 'hl.dsp.focus({ workspace = "emptym" })'

    # Launch the app in the current (empty) workspace
    hyprctl dispatch "hl.dsp.exec_cmd('$selected_app')"
fi