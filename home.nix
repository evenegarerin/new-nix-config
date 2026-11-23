{ pkgs, osConfig, ... }:

{
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
}
