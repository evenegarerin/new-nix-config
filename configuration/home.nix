{ config, lib, pkgs, ... }:

let
  user = config.my.user;
  home = config.users.users.${user}.home;

  userDirs = {
    DESKTOP = "Desktop";
    DOCUMENTS = "Documents";
    DOWNLOAD = "Downloads";
    MUSIC = "Music";
    PICTURES = "Pictures";
    PROJECTS = "Projects";
    PUBLICSHARE = "Public";
    TEMPLATES = "Templates";
    VIDEOS = "Videos";
  };

  userDirsFile = pkgs.writeText "user-dirs.dirs" (
    lib.concatStrings (
      lib.mapAttrsToList (key: dir: ''
        XDG_${key}_DIR="$HOME/${dir}"
      '') userDirs
    )
  );

  userDirsConf = pkgs.writeText "user-dirs.conf" ''
    enabled=False
  '';
in
{
  systemd.tmpfiles.rules = [
    "L+ ${home}/.config/user-dirs.dirs - - - - ${userDirsFile}"
    "L+ ${home}/.config/user-dirs.conf - - - - ${userDirsConf}"
  ]
  ++ lib.mapAttrsToList (_: dir: "d ${home}/${dir} 0755 ${user} users -") userDirs;
}
