{ config, pkgs, ... }:

let
  nixConfig = "/home/castle/nix-config/config";
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
      mkdir -p "$HOME/.config/VSCodium/User"
      mkdir -p "$HOME/.gnupg"

      # real dirs on purpose: ulauncher writes extensions.json/shortcuts.json next to
      # settings.json, and generates generated.css inside a user theme dir
      mkdir -p "$HOME/.config/ulauncher/user-themes/gruvbox"

      ln -sfn "${nixConfig}/elephant" "$HOME/.config/elephant"
      ln -sfn "${nixConfig}/gtk-3.0" "$HOME/.config/gtk-3.0"
      ln -sfn "${nixConfig}/gtk-4.0" "$HOME/.config/gtk-4.0"
      ln -sfn "${nixConfig}/hypr" "$HOME/.config/hypr"
      ln -sfn "${nixConfig}/kitty" "$HOME/.config/kitty"
      ln -sfn "${nixConfig}/nvim" "$HOME/.config/nvim"
      ln -sfn "${nixConfig}/qutebrowser" "$HOME/.config/qutebrowser"
      ln -sfn "${nixConfig}/swaync" "$HOME/.config/swaync"
      ln -sfn "${nixConfig}/ulauncher/settings.json" "$HOME/.config/ulauncher/settings.json"
      ln -sfn "${nixConfig}/ulauncher/user-themes/gruvbox/manifest.json" "$HOME/.config/ulauncher/user-themes/gruvbox/manifest.json"
      ln -sfn "${nixConfig}/ulauncher/user-themes/gruvbox/theme.css" "$HOME/.config/ulauncher/user-themes/gruvbox/theme.css"
      ln -sfn "${nixConfig}/ulauncher/user-themes/gruvbox/theme-gtk-3.20.css" "$HOME/.config/ulauncher/user-themes/gruvbox/theme-gtk-3.20.css"
      ln -sfn "${nixConfig}/vscodium/settings.json" "$HOME/.config/VSCodium/User/settings.json"
      ln -sfn "${nixConfig}/waybar" "$HOME/.config/waybar"
      ln -sfn "${nixConfig}/wofi" "$HOME/.config/wofi"
      ln -sfn "${nixConfig}/yazi" "$HOME/.config/yazi"
      ln -sfn "${nixConfig}/wallpapers" "$HOME/.config/wallpapers"
      ln -sfn "${nixConfig}/zsh/.zshrc" "$HOME/.zshrc"
      ln -sfn "${nixConfig}/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
      ln -sfn "${nixConfig}/tmux/.tmux.conf" "$HOME/.tmux.conf"
      ln -sfn "${nixConfig}/pcmanfm" "$HOME/.config/pcmanfm"
      ln -sfn "${nixConfig}/herdr/config.toml" "$HOME/.config/herdr/config.toml"
      ln -sfn "${nixConfig}/claude/keybindings.json" "$HOME/.claude/keybindings.json"

      for profile in "$HOME"/.config/mozilla/firefox/*.default; do
        [ -d "$profile" ] || continue
        mkdir -p "$profile/chrome"
        ln -sfn "${nixConfig}/firefox/userChrome.css" "$profile/chrome/userChrome.css"
      done
    '';
}
