-- Hyprland configuration

-- `require` turns dots into slashes, so hyprland.d is not reachable as a module name;
-- put the directory itself on the search path instead
local config_dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
package.path = package.path .. ";" .. config_dir .. "/hyprland.d/?.lua"

require("env")
require("autostart")
require("look") -- before fullscreen: sets the gaps/rounding it overrides
require("monitors") -- before lid: generic monitor rules first
require("fullscreen")
require("lid")
require("focus")
require("workspaces")
require("media")
require("screenshot")
require("resize")
require("virtual-mouse")
require("keybinds")
require("launcher")
require("special")
