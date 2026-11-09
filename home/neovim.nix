{ pkgs, lib, ... }:
let
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
