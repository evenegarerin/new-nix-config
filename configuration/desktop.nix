{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  filechooserTerminal = "${lib.getExe pkgs.kitty} --class superfile";

  filechooserWrapper = pkgs.writeShellScript "termfilechooser-wrapper" ''
    multiple="$1"
    directory="$2"
    path="$4"
    out="$5"

    if [ "$directory" = "1" ]; then
      ${filechooserTerminal} ${lib.getExe pkgs.yazi} --chooser-file="$out" --cwd-file="$out.1" "$path"
      if [ ! -s "$out" ] && [ -s "$out.1" ]; then
        cat "$out.1" > "$out"
      fi
      rm -f "$out.1"
    elif [ "$multiple" = "1" ]; then
      ${filechooserTerminal} ${lib.getExe pkgs.yazi} --chooser-file="$out" "$path"
    else
      ${filechooserTerminal} ${lib.getExe pkgs-unstable.superfile} --chooser-file="$out" "$path"
    fi
  '';

  filechooserConfig = pkgs.writeText "termfilechooser-config" ''
    [filechooser]
    cmd=${filechooserWrapper}
    default_dir=$HOME
    open_mode=suggested
    save_mode=suggested
  '';
in
{
  # Wayland session stack: compositor, greeter, portals, and the desktop auth/service agents.
  security.polkit.enable = true;

  security.polkit.adminIdentities = [ "unix-user:0" ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "uwsm start -e -D Hyprland -- hyprland.desktop -- --locked-cmd hyprlock";
        user = config.my.user;
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

  services.upower.enable = true;

  services.blueman.enable = true;

  services.elephant.enable = true;

  systemd.user.services.elephant.enableDefaultPath = false;

  xdg.portal = {
    enable = true;

    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
      };
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-termfilechooser
    ];
  };

  systemd.user.services.xdg-desktop-portal-termfilechooser.serviceConfig.ExecStart = [
    ""
    "${pkgs.xdg-desktop-portal-termfilechooser}/libexec/xdg-desktop-portal-termfilechooser -c ${filechooserConfig}"
  ];
}
