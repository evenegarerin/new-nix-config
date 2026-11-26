{
  pkgs,
  lib,
  config,
  ...
}:
let
  user = config.my.user;
  home = config.users.users.${user}.home;
  configDir = "${home}/nix-config/config";

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
  environment.systemPackages = [ parsers ];
  environment.pathsToLink = [ "/share/nvim" ];

  systemd.tmpfiles.rules = [
    "L+ ${home}/.config/nvim - - - - ${configDir}/nvim"
  ];
}
