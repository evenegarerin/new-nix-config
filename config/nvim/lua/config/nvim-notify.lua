local nvim_notify = require("notify")
nvim_notify.setup {
  -- Animation style
  stages = "fade_in_slide_out",
  -- Default timeout for notifications
  timeout = 1500,
  -- NOTE: the target hardcodes #2E3440, a Nord colour, which clashes badly with
  -- kanagawa-dragon. nvim-notify needs a concrete colour here because
  -- custom-autocmd.lua makes Normal transparent -- it cannot inherit a bg that
  -- does not exist. This is kanagawa-dragon's own background.
  background_colour = "#181616",
}

vim.notify = nvim_notify
