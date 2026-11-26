{ pkgs, ... }:

{
  environment.systemPackages = [ (pkgs.callPackage ../../selfBuild/vimnm.nix { }) ];

  my.tuiApps.vimnm = {
    desktopName = "Vimnm";
    genericName = "Wlan Manager";
    categories = [ "Network" ];
  };
}
