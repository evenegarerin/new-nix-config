-- Flake-aware option completion for NixOS and home-manager. Moved here from the
-- pre-rebuild config's inline nixd block (4dedfd2^:lua/plugins/lsp.lua).
--
-- Two fixes while moving it: the old config pointed at /home/castle/nixos-config,
-- which does not exist (the repo is /home/castle/nix-config), and asked for
-- nixpkgs-fmt, which is not installed -- nixfmt is.
---@type vim.lsp.Config
return {
  settings = {
    nixd = {
      formatting = {
        command = { "nixfmt" },
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "/home/castle/nix-config").nixosConfigurations.default.options',
        },
        home_manager = {
          expr = '(builtins.getFlake "/home/castle/nix-config").nixosConfigurations.default.options.home-manager.users.type.getSubOptions []',
        },
      },
    },
  },
}
