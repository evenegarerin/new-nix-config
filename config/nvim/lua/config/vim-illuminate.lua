require("illuminate").configure {
  providers = {
    "lsp",
    "treesitter",
  },
  filetypes_denylist = {},
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
