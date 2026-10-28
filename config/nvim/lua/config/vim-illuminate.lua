require("illuminate").configure {
  providers = {
    "lsp",
    "treesitter",
  },
  filetypes_denylist = {},
  -- NOTE: the target's list is go/java/javascript/json/lua/python/sh/toml/
  -- typescript/yaml -- notably without `nix`, the language this repo is mostly
  -- written in. go and java are dropped; nix, elm, css, html and markdown added.
  filetypes_allowlist = {
    "css",
    "elm",
    "html",
    "javascript",
    "json",
    "lua",
    "markdown",
    "nix",
    "python",
    "sh",
    "toml",
    "typescript",
    "yaml",
  },
  min_count_to_highlight = 2,
}
