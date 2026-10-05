if vim.fn.argc() == 0 then
  vim.cmd("edit .")
end

require("options")
require("keymaps")
require("autocmd")
require("highlights")
require("commands")

require("lazy")