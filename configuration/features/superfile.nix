{ pkgs-unstable, ... }:

{
  environment.systemPackages = [ pkgs-unstable.superfile ];

  my.links = {
    ".config/superfile/config.toml" = "superfile/config.toml";
    ".config/superfile/hotkeys.toml" = "superfile/hotkeys.toml";
  };
}
