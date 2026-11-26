{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.rmpc ];

  my.tuiApps.rmpc = {
    desktopName = "Rmpc";
    genericName = "Music Player Interface";
    categories = [
      "Audio"
      "Music"
      "Player"
    ];
  };
}
