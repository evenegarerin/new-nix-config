{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.yazi ];

  my.links.".config/yazi" = "yazi";
}
