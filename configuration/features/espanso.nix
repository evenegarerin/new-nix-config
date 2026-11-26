{ pkgs, config, ... }:

let
  user = config.my.user;
  home = config.users.users.${user}.home;
  configDir = "${home}/nix-config/config";
in
{
  services.espanso = {
    enable = true;
    package = pkgs.espanso-wayland;
  };

  systemd.tmpfiles.rules = [
    "d ${home}/.config/espanso 0755 ${user} users -"
    "d ${home}/.config/espanso/config 0755 ${user} users -"
    "d ${home}/.config/espanso/match 0755 ${user} users -"
    "L+ ${home}/.config/espanso/config/default.yml - - - - ${configDir}/espanso/config/default.yml"
    "L+ ${home}/.config/espanso/match/base.yml - - - - ${configDir}/espanso/match/base.yml"
  ];
}
