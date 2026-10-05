{ config, pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;

    package = pkgs.borealis-cursors;
    name = "Borealis-cursors";
    size = 24;

    hyprcursor.enable = true;
    gtk.enable = true;
  };

  home.file = {
    ".config/gtk-3.0".source = config.lib.file.mkOutOfStoreSymlink ./config/gtk-3.0;
    ".config/gtk-4.0".source = config.lib.file.mkOutOfStoreSymlink ./config/gtk-4.0;
    ".config/hypr".source = config.lib.file.mkOutOfStoreSymlink ./config/hypr;
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink ./config/kitty;
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink ./config/nvim;
    ".config/qutebrowser".source = config.lib.file.mkOutOfStoreSymlink ./config/qutebrowser;
    ".config/swaync".source = config.lib.file.mkOutOfStoreSymlink ./config/swaync;
    ".config/vscodium/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink ./config/vscodium/settings.json;
    ".config/waybar".source = config.lib.file.mkOutOfStoreSymlink ./config/waybar;
    ".config/wofi".source = config.lib.file.mkOutOfStoreSymlink ./config/wofi;
    ".config/yazi".source = config.lib.file.mkOutOfStoreSymlink ./config/yazi;
    ".config/.zshrc".source = config.lib.file.mkOutOfStoreSymlink ./config/zsh/.zshrc;
    ".config/wallpapers".source = config.lib.file.mkOutOfStoreSymlink ./config/wallpapers;
  };
}