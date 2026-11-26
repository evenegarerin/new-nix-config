{ pkgs, pkgs-unstable, ... }:

{
  imports = [ ../../selfBuild/hyprland-session-restore.nix ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };

  services.hyprland-session-restore.enable = true;

  environment.systemPackages =
    (with pkgs; [
      hyprcursor
      hyprpaper
      hyprlock
      hypridle
    ])
    ++ (with pkgs-unstable; [
      hyprshot
      hyprmod
    ]);

  my.links.".config/hypr" = "hypr";
}
