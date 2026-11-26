{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.bluetui ];

  my.tuiApps.bluetui = {
    desktopName = "Bluetui";
    genericName = "Bluetooth Manager";
    categories = [ "Network" ];
  };
}
