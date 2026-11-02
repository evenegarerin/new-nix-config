-- Volume, brightness and media player keys.

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume 0 -10%"), { description = "Decrease output volume" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume 0 +10%"), { description = "Increase output volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl -- set-sink-mute 0 toggle"), { description = "Toggle output mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl -- set-source-mute 0 toggle"), { description = "Toggle input mute" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { description = "Decrease monitor brightness" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +10%"), { description = "Increase monitor brightness" })

hl.bind("XF86PickupPhone", hl.dsp.exec_cmd("playerctl play"), { description = "Media Player play" })
hl.bind("XF86HangupPhone", hl.dsp.exec_cmd("playerctl -a pause"), { description = "Media Player pause" })

hl.bind("F1", hl.dsp.exec_cmd("playerctl --player=playerctld play-pause"), { description = "Media Player toggle play" })
