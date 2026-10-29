local keymap = vim.keymap
local gitlinker = require("gitlinker")

gitlinker.setup {
  mappings = nil,
}

keymap.set({ "n", "v" }, "<leader>gl", function()
  local mode = string.lower(vim.fn.mode())
  gitlinker.get_buf_range_url(mode)
end, {
  silent = true,
  desc = "Git: get permlink",
})

keymap.set("n", "<leader>gbr", function()
  gitlinker.get_repo_url {
    action_callback = gitlinker.actions.open_in_browser,
  }
end, {
  silent = true,
  desc = "Git: browse repo in browser",
})
