{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.swaynotificationcenter ];

  my.links.".config/swaync" = "swaync";
}
