{ pkgs, ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "superfile.desktop" ];
  };
}
