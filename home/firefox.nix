{ config, ... }:

let
  configDir = "${config.home.homeDirectory}/nix-config/config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${configDir}/${path}";
in
{
  # Firefox and its chrome link live together: the link's target path is derived from the home-manager-managed profile.
  # The system side (fx-autoconfig, which makes chrome/ take effect, plus policies) is in configuration/firefox.nix.
  programs.firefox = {
    enable = true;
    # The NixOS-built Firefox carries the fx-autoconfig mozilla.cfg; a home-manager-built one would shadow it on PATH without it.
    package = null;
    profiles.default = {
      id = 0;
      isDefault = true;
    };
  };

  home.file."${config.programs.firefox.configPath}/${config.programs.firefox.profiles.default.path}/chrome".source =
    link "firefox/chrome";
}
