{ pkgs, osConfig, ... }:

{
  imports = [
    ./home/activation.nix
    ./home/desktopEntries.nix
    ./home/mimeApps.nix
    ./home/configLinks.nix
    ./home/firefox.nix
    ./home/neovim.nix
  ];

  gtk = {
    enable = true;

    theme = {
      inherit (osConfig.my.theme.gtk) name package;
    };

    iconTheme = {
      inherit (osConfig.my.theme.icons) name package;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  home.pointerCursor = {
    enable = true;

    package = pkgs.callPackage ./selfBuild/borealis-cursors-hyprcursor.nix { };
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
