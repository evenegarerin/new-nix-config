{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.waybar ];

  my.links.".config/waybar" = "waybar";
}
