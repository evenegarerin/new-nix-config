-- texlab handles the editor-intelligence side only: references, labels,
-- citations, rename, and chktex lint. vimtex owns compilation and viewing
-- (lua/plugin_specs.lua), so `build.onSave` stays off -- otherwise every write
-- fires two latexmk runs at the same aux files.
---@type vim.lsp.Config
return {
  settings = {
    texlab = {
      build = {
        executable = "latexmk",
        args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
        onSave = false,
      },
      forwardSearch = {
        executable = "zathura",
        args = { "--synctex-forward", "%l:1:%f", "%p" },
      },
      chktex = {
        onOpenAndSave = true,
        onEdit = false,
      },
      diagnosticsDelay = 300,
    },
  },
}
