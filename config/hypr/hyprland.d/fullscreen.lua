-- Fake fullscreen: strips gaps and rounding system wide, and keeps that choice
-- across config reloads. Also stops clients from forcing real fullscreen.

local common = require("common")

local mainMod = common.mainMod
local read_state = common.read_state
local write_state = common.write_state

hl.window_rule({
  match = {
    fullscreen_state_client = 1,
  },
  fullscreen_state = "0 0",
})

local gaps_in_normal = 2
local gaps_out_normal = 4
local rounding_normal = 10

local function apply_layout(state)
  if state then
    hl.config({
      general = { gaps_in = 0, gaps_out = 0 },
      decoration = { rounding = 0 },
    })
  else
    hl.config({
      general = { gaps_in = gaps_in_normal, gaps_out = gaps_out_normal },
      decoration = { rounding = rounding_normal },
    })
  end
end

local function set_fullscreen(state)
  local active_state = read_state("fullscreen", false)

  if state ~= active_state then
    if state then
      hl.dispatch(hl.dsp.exec_cmd("qs ipc call bar hide"))
    else
      hl.dispatch(hl.dsp.exec_cmd("qs ipc call -- bar show"))
    end

    apply_layout(state)

    write_state("fullscreen", state)
  end
end

hl.on("hyprland.start", function()
  write_state("fullscreen", true)
end)

apply_layout(read_state("fullscreen", true))

hl.bind(mainMod .. " + F", function()
  set_fullscreen(not read_state("fullscreen", false))
end, { description = "Toggle fake fullscreen for entire system" })

hl.bind(
  mainMod .. " + SHIFT + F",
  hl.dsp.window.fullscreen({ mode = "fullscreen" }),
  { description = "Toggle true fullscreen for current window" }
)
