-- Carried over from the pre-rebuild config (4dedfd2^:lua/plugins/lsp.lua).
-- elm-format is on PATH via elmPackages.elm-format in configuration.nix.
---@type vim.lsp.Config
return {
  settings = {
    elmLS = {
      formatting = {
        command = { "elm-format" },
      },
    },
  },
}
