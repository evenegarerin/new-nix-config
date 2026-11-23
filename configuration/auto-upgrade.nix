{ config, pkgs, ... }:

let
  user = config.my.user;
  home = config.users.users.${user}.home;
  flakeDir = "${home}/nix-config";
in

{
  system.autoUpgrade = {
    enable = true;
    flake = "${flakeDir}#default";
    operation = "boot";
    upgrade = false;
    flags = [ "--impure" ];
    dates = "weekly";
    persistent = true;
    randomizedDelaySec = "5min";
  };

  systemd.services.nixos-upgrade.serviceConfig.ExecStartPre =
    "${pkgs.util-linux}/bin/runuser -u ${user} -- ${pkgs.coreutils}/bin/env HOME=${home} nix flake update --flake ${flakeDir}";
}
