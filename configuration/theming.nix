{ lib, pkgs, ... }:

{
  # GTK/Qt look: themes, fonts, and the glib schema path that gsettings needs to find them.
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = "Andromeda";
            color-scheme = "prefer-dark";
            monospace-font-name = "JetBrainsMono Nerd Font";
            icon-theme = "Papirus-Dark";
          };
          "org/gnome/TextEditor" = {
            auto-indent = true;
            show-line-numbers = true;
            highlight-current-line = true;
            spellcheck = false;
            tab-width = lib.gvariant.mkUint32 4;
            use-system-font = true;
            wrap-text = true;
          };
        };
      }
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    plus-jakarta-sans
  ];

  environment.etc."xdg/kdeglobals".source = pkgs.runCommand "kdeglobals" { } ''
    cat ${pkgs.dracula-theme}/share/color-schemes/Dracula.colors > $out
  '';

  environment.pathsToLink = [
    "/share/glib-2.0/schemas"
  ];
}
