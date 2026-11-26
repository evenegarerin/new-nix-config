{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.pcmanfm ];

  my.links.".config/pcmanfm" = "pcmanfm";
}
