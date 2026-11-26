{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.imv ];

  xdg.mime.defaultApplications = {
    "image/png" = [ "imv.desktop" ];
    "image/jpeg" = [ "imv.desktop" ];
  };
}
