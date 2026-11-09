{ ... }:

{
  # System-wide Firefox: fx-autoconfig plus enterprise policies. The profile and its chrome/ symlink are in home/firefox.nix.
  programs.firefox = {
    enable = true;
    autoConfig = builtins.readFile (
      builtins.fetchurl {
        url = "https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/program/config.js";
        sha256 = "1mx679fbc4d9x4bnqajqx5a95y1lfasvf90pbqkh9sm3ch945p40";
      }
    );
    policies = (builtins.fromJSON (builtins.readFile ../config/firefox/policies.json)).policies;
  };
}
