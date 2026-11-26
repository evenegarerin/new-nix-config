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
    mkdir -p $out/share/nvim/site/parser
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        lang: pkg: "ln -s ${pkg}/parser $out/share/nvim/site/parser/${lang}.so"
      ) grammars
    )}
  '';
in
{
  environment.systemPackages = [
    pkgs.neovim
    parsers
  ];
  environment.pathsToLink = [ "/share/nvim" ];

  environment.variables.EDITOR = "nvim";

  my.links.".config/nvim" = "nvim";
}
