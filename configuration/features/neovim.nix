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

  nvim-zi = pkgs.writeShellScript "nvim-zi" ''
    if [ "$#" -gt 0 ]; then
      exec nvim "$@"
    fi

    dir=$(zoxide query -i) && cd "$dir"
    exec nvim "''${dir:-.}"
  '';
in
{
  environment.systemPackages = [
    pkgs.neovim
    parsers
  ];
  environment.pathsToLink = [ "/share/nvim" ];

  environment.variables.EDITOR = "nvim";

  my.tuiApps.nvim = {
    desktopName = "Neovim";
    genericName = "Text Editor";
    categories = [
      "Development"
      "IDE"
      "TextEditor"
    ];
    command = "${nvim-zi} %F";
    icon = "nvim";
  };

  xdg.mime.defaultApplications."application/json" = [ "nvim" ];

  my.links.".config/nvim" = "nvim";
}
