# Tree-sitter parsers for Neovim.
#
# The `tree-sitter-grammars.*` packages each expose a bare `$out/parser` (the
# compiled shared object), but Neovim looks for `<runtimepath>/parser/<lang>.so`.
# Putting the packages in `environment.systemPackages` therefore does nothing --
# they end up as `/run/current-system/sw/parser`, which nothing reads. Rename
# them into a single directory instead and link that into
# `~/.local/share/nvim/site`, which is on Neovim's default runtimepath.
#
# The matching queries come from nvim-treesitter's bundled `runtime/` directory;
# see the runtimepath line in config/nvim/lua/config/treesitter.lua.
{ pkgs, lib, ... }:
let
  # Language name -> grammar package. The language name is what Neovim looks up,
  # so it has to match `vim.treesitter.language.get_lang(ft)`: filetype `sh`
  # resolves to language `bash`, for instance.
  grammars = with pkgs.tree-sitter-grammars; {
    nix = tree-sitter-nix;
    json = tree-sitter-json;
    toml = tree-sitter-toml;
    yaml = tree-sitter-yaml;
    css = tree-sitter-css;
    bash = tree-sitter-bash;
  };

  parsers = pkgs.runCommand "nvim-treesitter-parsers" { } ''
    mkdir -p $out/parser
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (lang: pkg: "ln -s ${pkg}/parser $out/parser/${lang}.so") grammars
    )}
  '';
in
{
  xdg.dataFile."nvim/site/parser".source = "${parsers}/parser";
}
