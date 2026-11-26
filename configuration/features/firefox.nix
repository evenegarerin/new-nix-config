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
    policies = (builtins.fromJSON (builtins.readFile "${config.my.configDir}/firefox/policies.json")).policies;
  };

  environment.variables.BROWSER = "firefox";

  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "text/html" = [ "firefox.desktop" ];
  };

  my.links.".config/mozilla/firefox/default/chrome" = "firefox/chrome";
  my.dirs.".config/mozilla/firefox/default" = "0700";

  systemd.tmpfiles.rules = [
    "L+ ${firefoxDir}/profiles.ini - - - - ${profilesIni}"
  ];
}
