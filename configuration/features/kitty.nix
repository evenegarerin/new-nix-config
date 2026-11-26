{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.kitty ];

  environment.variables.TERMINAL = "kitty";

  my.links.".config/kitty" = "kitty";
}
