-- Flake-aware option completion for NixOS and home-manager. Moved here from the
-- pre-rebuild config's inline nixd block (4dedfd2^:lua/plugins/lsp.lua).
local flake = '(builtins.getFlake "' .. vim.env.HOME .. '/nix-config")'

---@type vim.lsp.Config
return {
  settings = {
    nixd = {
      formatting = {
        command = { "nixfmt" },
      },
      options = {
        nixos = {
          expr = flake .. ".nixosConfigurations.default.options",
        },
        home_manager = {
          expr = flake .. ".nixosConfigurations.default.options.home-manager.users.type.getSubOptions []",
        },
      },
    },
  },
}
