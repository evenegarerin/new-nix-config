{ pkgs, ... }:

{
  imports = [
    ./home/desktopEntries.nix
    ./home/mimeApps.nix
    ./home/configLinks.nix
    ./home/firefox.nix
  ];

  home.pointerCursor = {
    enable = true;

    package = pkgs.borealis-cursors;
    name = "Borealis-cursors";
    size = 24;

    hyprcursor.enable = true;
    gtk.enable = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    desktop = "$HOME/Desktop";
  };
}
