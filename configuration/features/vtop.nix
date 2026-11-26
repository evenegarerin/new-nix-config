{ pkgs, ... }:

{
  environment.systemPackages = [ (pkgs.callPackage ../../selfBuild/vtop.nix { }) ];

  my.tuiApps.vtop = {
    desktopName = "Vtop";
    genericName = "System Monitor";
    categories = [
      "System"
      "Utility"
      "Monitor"
    ];
  };
}
