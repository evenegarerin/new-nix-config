{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.typtea ];

  my.tuiApps.typtea = {
    desktopName = "Typtea";
    genericName = "Typing Trainer";
    categories = [ "Game" ];
  };
}
