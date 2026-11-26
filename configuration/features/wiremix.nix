{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.wiremix ];

  my.tuiApps.wiremix = {
    desktopName = "Wiremix";
    genericName = "Volume Controller";
    categories = [
      "Audio"
      "Mixer"
    ];
  };
}
