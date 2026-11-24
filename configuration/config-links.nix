{ config, lib, ... }:

let
  user = config.my.user;
  home = config.users.users.${user}.home;
  configDir = "${home}/nix-config/config";

  xdgLinks =
    lib.genAttrs [
      "elephant"
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
      "herdr/config.toml"
      "keyd/app.conf"
      "superfile/config.toml"
      "superfile/hotkeys.toml"
      "espanso/config/default.yml"
      "espanso/match/base.yml"
    ] (name: name)
    // {
      "VSCodium/User/settings.json" = "vscodium/settings.json";
    };

  homeLinks = {
    ".zshrc" = "zsh/.zshrc";
    ".config/starship.toml" = "zsh/starship.toml";
    ".tmux.conf" = "tmux/.tmux.conf";
    ".gnupg/gpg-agent.conf" = "gnupg/gpg-agent.conf";
    ".claude/keybindings.json" = "claude/keybindings.json";
    ".claude/statusline.sh" = "claude/statusline.sh";
  };

  links = lib.mapAttrs' (name: lib.nameValuePair ".config/${name}") xdgLinks // homeLinks;

  dirs = {
    ".config" = "0755";
    ".config/herdr" = "0755";
    ".config/keyd" = "0755";
    ".config/superfile" = "0755";
    ".config/espanso" = "0755";
    ".config/espanso/config" = "0755";
    ".config/espanso/match" = "0755";
    ".config/VSCodium" = "0700";
    ".config/VSCodium/User" = "0755";
    ".gnupg" = "0700";
    ".claude" = "0755";
  };
in
{
  systemd.tmpfiles.rules =
    lib.mapAttrsToList (path: mode: "d ${home}/${path} ${mode} ${user} users -") dirs
    ++ lib.mapAttrsToList (path: target: "L+ ${home}/${path} - - - - ${configDir}/${target}") links;
}
