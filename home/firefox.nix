{ config, ... }:

let
  configDir = "${config.home.homeDirectory}/nix-config/config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${configDir}/${path}";
in
{
  # Firefox and its chrome link live together: the link's target path is derived from the home-manager-managed profile.
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      isDefault = true;
    };
  };

  home.file."${config.programs.firefox.configPath}/${config.programs.firefox.profiles.default.path}/chrome".source =
    link "firefox/chrome";
}
