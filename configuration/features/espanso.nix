{ pkgs, ... }:

{
  services.espanso = {
    enable = true;
    package = pkgs.espanso-wayland;
  };

  my.links = {
    ".config/espanso/config/default.yml" = "espanso/config/default.yml";
    ".config/espanso/match/base.yml" = "espanso/match/base.yml";
  };
}
