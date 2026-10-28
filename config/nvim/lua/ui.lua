--- Colorscheme and the highlight overrides that have to survive it.
---
--- The target (../nvim.bak/lua/ui.lua) ships 25 schemes and picks one at random
--- on every start. We take the `use_theme` helper and exactly one scheme --
--- a random scheme makes every highlight problem irreproducible.

-- NOTE: the `custom_highlight` ColorScheme hook used to live here, because
-- Stage 3 needed the transparency the moment it applied a colorscheme. Stage 1
-- moved it to its proper home in lua/custom-autocmd.lua, which is required
-- before this module -- so the hook is still registered before `use_theme` runs.

local use_theme = function(name)
  local ok, err = pcall(vim.cmd.colorscheme, name)

  if not ok then
    vim.notify(
      string.format("Failed to load colorscheme %s, err: %s", name, err),
      vim.log.levels.WARN
    )

    vim.cmd.colorscheme("default")
  end
end

use_theme("kanagawa-dragon")

-- NOTE: the target also enables the experimental message UI here
-- (ui.lua:149-170, `vim._core.ui2`). Skipped: private API, and it expects
-- nvim 0.12.6 while 0.12.4 is installed.
