{
  config,
  lib,
  pkgs,
  ...
}:

let
  theme = config.my.theme;
in

{
  options.my.theme = {
    gtk = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "GTK theme name.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        description = "Package providing the GTK theme.";
      };
    };

    icons = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Icon theme name.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        description = "Package providing the icon theme.";
      };
    };

    monoFont = lib.mkOption {
      type = lib.types.str;
      description = "Monospace font family.";
    };
  };

  config = {
    my.theme = {
      gtk = {
        name = "Andromeda";
        package = pkgs.andromeda-gtk-theme;
      };

      icons = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      monoFont = "JetBrainsMono Nerd Font";
    };

    # GTK/Qt look: themes, fonts, and the glib schema path that gsettings needs to find them.
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              gtk-theme = theme.gtk.name;
              color-scheme = "prefer-dark";
              monospace-font-name = theme.monoFont;
              icon-theme = theme.icons.name;
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

    # environment.etc."xdg/kdeglobals".source = pkgs.runCommand "kdeglobals" { } ''
    #   cat ${pkgs.dracula-theme}/share/color-schemes/Dracula.colors > $out
    # '';

    environment.etc."xdg/kdeglobals".source =
      "${pkgs.dracula-theme}/share/color-schemes/Dracula.colors";

    environment.pathsToLink = [
      "/share/glib-2.0/schemas"
    ];
  };
}
