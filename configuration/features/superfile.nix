{ pkgs-unstable, ... }:

{
  environment.systemPackages = [ pkgs-unstable.superfile ];

  my.tuiApps.superfile = {
    desktopName = "superfile";
    genericName = "File Manager";
    categories = [
      "System"
      "FileTools"
      "FileManager"
    ];
    command = "superfile %F";
    icon = "system-file-manager";
    mimeTypes = [ "inode/directory" ];
  };

  xdg.mime.defaultApplications."inode/directory" = [ "superfile.desktop" ];

  my.links = {
    ".config/superfile/config.toml" = "superfile/config.toml";
    ".config/superfile/hotkeys.toml" = "superfile/hotkeys.toml";
  };
}
