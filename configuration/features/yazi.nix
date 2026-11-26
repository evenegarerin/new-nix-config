{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.yazi ];

  my.tuiApps.yazi = {
    desktopName = "Yazi";
    genericName = "File Manager";
    categories = [
      "System"
      "FileManager"
    ];
  };

  my.links.".config/yazi" = "yazi";
}
