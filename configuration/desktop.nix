{ pkgs, pkgs-unstable, ... }:

{
  # Wayland session stack: compositor, greeter, portals, and the desktop auth/service agents.
  security.polkit.enable = true;

  security.polkit.adminIdentities = [ "unix-user:0" ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "uwsm start -e -D Hyprland -- hyprland.desktop -- --locked-cmd hyprlock";
        user = "castle";
      };
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;

  services.blueman.enable = true;

  services.elephant.enable = true;

  systemd.user.services.elephant.enableDefaultPath = false;

  xdg.portal = {
    enable = true;

    config = {
      common = {
        default = "gtk";
      };
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}
