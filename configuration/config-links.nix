{ config, lib, ... }:

let
  user = config.my.user;
  home = config.users.users.${user}.home;
  cfg = config.my;

  parents =
    path:
    let
      parts = lib.splitString "/" path;
    in
    map (n: lib.concatStringsSep "/" (lib.take n parts)) (lib.range 1 (builtins.length parts - 1));

  dirs =
    lib.genAttrs (lib.unique (lib.concatMap parents (builtins.attrNames cfg.links))) (_: "0755")
    // cfg.dirs;
in
{
  options.my = {
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "${home}/nix-config/config";
      description = "Directory in the repository that holds the linked config files.";
    };

    links = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Symlinks in the home directory, mapping a path relative to home to a path relative to my.configDir.";
    };

    dirs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Directories in the home directory with a non-default mode, mapping a path relative to home to its mode.";
    };
  };

  config = {
    systemd.tmpfiles.rules =
      lib.mapAttrsToList (path: mode: "d ${home}/${path} ${mode} ${user} users -") dirs
      ++ lib.mapAttrsToList (path: target: "L+ ${home}/${path} - - - - ${cfg.configDir}/${target}") cfg.links;
  };
}
