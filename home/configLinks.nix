{
  config,
  lib,
  ...
}:

let
  configDir = "${config.home.homeDirectory}/nix-config/config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${configDir}/${path}";
in
{
  xdg.configFile =
    # Directories that share the same name in this configuration and in ~/.config
    lib.genAttrs
      [
        "elephant"
        "gtk-3.0"
        "gtk-4.0"
        "hypr"
        "kitty"
        "nvim"
        "qutebrowser"
        "swaync"
        "waybar"
        "yazi"
        "wallpapers"
        "pcmanfm"
        "walker"
        "quickshell"
      ]
      (name: {
        source = link name;
      })
    // {
      "VSCodium/User/settings.json".source = link "vscodium/settings.json";
      "herdr/config.toml".source = link "herdr/config.toml";
      "keyd/app.conf".source = link "keyd/app.conf";
    };

  home.file = {
    ".zshrc".source = link "zsh/.zshrc";
    ".tmux.conf".source = link "tmux/.tmux.conf";
    ".gnupg/gpg-agent.conf".source = link "gnupg/gpg-agent.conf";
    ".claude/keybindings.json".source = link "claude/keybindings.json";
    ".claude/statusline.sh".source = link "claude/statusline.sh";
  };
}
