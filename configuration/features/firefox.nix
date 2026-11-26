{ config, pkgs, ... }:

let
  user = config.my.user;
  home = config.users.users.${user}.home;
  firefoxDir = "${home}/.config/mozilla/firefox";

  profilesIni = pkgs.writeText "profiles.ini" ''
    [General]
    StartWithLastProfile=1
    Version=2

    [Profile0]
    Default=1
    IsRelative=1
    Name=default
    Path=default
  '';
in
{
  programs.firefox = {
    enable = true;
    autoConfig = builtins.readFile (
      builtins.fetchurl {
        url = "https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/dfdab5684faffc112b76ccb1d8cab7f75da0102c/program/config.js";
        sha256 = "1mx679fbc4d9x4bnqajqx5a95y1lfasvf90pbqkh9sm3ch945p40";
      }
    );
    policies = (builtins.fromJSON (builtins.readFile ../config/firefox/policies.json)).policies;
  };

  systemd.tmpfiles.rules = [
    "d ${home}/.config/mozilla 0755 ${user} users -"
    "d ${firefoxDir} 0755 ${user} users -"
    "d ${firefoxDir}/default 0700 ${user} users -"
    "L+ ${firefoxDir}/profiles.ini - - - - ${profilesIni}"
    "L+ ${firefoxDir}/default/chrome - - - - ${home}/nix-config/config/firefox/chrome"
  ];
}
