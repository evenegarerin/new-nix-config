{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.vscodium ];

  my.links.".config/VSCodium/User/settings.json" = "vscodium/settings.json";
  my.dirs.".config/VSCodium" = "0700";
}
