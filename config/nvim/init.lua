-- Incrementally rebuilt Neovim config.
-- The full target setup lives in ../nvim.bak -- see README.md for the staged plan.
--
-- The require order below mirrors ../nvim.bak/init.lua exactly. Uncomment each
-- line as the corresponding stage from README.md lands, never reorder them.

vim.loader.enable()

-- Stage 0: platform flags, leader, builtin plugin disables
require("globals")

-- Stage 0: option settings
require("options")

-- Stage 1: autocommands
require("custom-autocmd")

-- Stage 1: user-defined mappings
require("mappings")

-- Stage 3: lazy.nvim bootstrap + all plugin specs
require("plugin_specs")

-- Stage 4: LSP. Must come AFTER plugin_specs, nvim-lspconfig is loaded there.
require("lsp_conf")

-- Stage 4: diagnostic display config
require("diagnostic-conf")

-- Stage 3: colorscheme. Must come LAST so the ColorScheme autocmd defined in
-- custom-autocmd.lua is already registered when the scheme is applied.
require("ui")
