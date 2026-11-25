{ ... }:

{
  xdg.mime.defaultApplications = {
    "inode/directory" = [ "superfile.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "text/html" = [ "firefox.desktop" ];
    "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    "image/png" = [ "imv.desktop" ];
    "image/jpeg" = [ "imv.desktop" ];
    "application/json" = [ "nvim" ];
  };
}
