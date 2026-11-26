{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.walker ];

  services.elephant.enable = true;

  systemd.user.services.elephant.enableDefaultPath = false;

  my.links = {
    ".config/walker" = "walker";
    ".config/elephant" = "elephant";
  };
}
