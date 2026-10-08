{ config, pkgs, ... }:

let
  nixConfig = "/home/castle/nix-config";
in
{
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

  home.activation.createConfigSymlinks =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config"
      mkdir -p "$HOME/.config/vscodium/User/settings.json"
      mkdir -p "$HOME/.gnupg"

      ln -sfn "${nixConfig}/config/gtk-3.0" "$HOME/.config/gtk-3.0"
      ln -sfn "${nixConfig}/config/gtk-4.0" "$HOME/.config/gtk-4.0"
      ln -sfn "${nixConfig}/config/hypr" "$HOME/.config/hypr"
      ln -sfn "${nixConfig}/config/kitty" "$HOME/.config/kitty"
      ln -sfn "${nixConfig}/config/nvim" "$HOME/.config/nvim"
      ln -sfn "${nixConfig}/config/qutebrowser" "$HOME/.config/qutebrowser"
      ln -sfn "${nixConfig}/config/swaync" "$HOME/.config/swaync"
      ln -sfn "${nixConfig}/config/vscodium/settings.json" "$HOME/.config/vscodium/User/settings.json"
      ln -sfn "${nixConfig}/config/waybar" "$HOME/.config/waybar"
      ln -sfn "${nixConfig}/config/wofi" "$HOME/.config/wofi"
      ln -sfn "${nixConfig}/config/yazi" "$HOME/.config/yazi"
      ln -sfn "${nixConfig}/config/wallpapers" "$HOME/.config/wallpapers"
      ln -sfn "${nixConfig}/config/zsh/.zshrc" "$HOME/.zshrc"
      ln -sfn "${nixConfig}/config/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
    '';
}
