{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.services.hyprland-session-restore;
  scripts = ./hyprland-session-restore;
in
{
  options.services.hyprland-session-restore = {
    enable = lib.mkEnableOption "Hyprland session restore";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.hyprland-session-restore = {
      description = "Restore Hyprland session";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [
        config.programs.hyprland.package
        pkgs-unstable.quickshell
        pkgs.jq
        pkgs.procps
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "hyprland-session-restore";
        ExecStart = "${pkgs.bash}/bin/bash ${scripts}/onBoot.sh";
      };
    };

    systemd.user.services.hyprland-session-restore-apply = {
      description = "Apply saved Hyprland session";
      path = [
        config.programs.hyprland.package
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "hyprland-session-restore";
        ExecStart = "${pkgs.bash}/bin/bash ${scripts}/restore.sh";
      };
    };

    systemd.user.services.hyprland-session-restore-skip = {
      description = "Skip Hyprland session restore";
      path = [ config.programs.hyprland.package ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash ${scripts}/skip.sh";
      };
    };

    systemd.user.services.hyprland-session-restore-timer = {
      description = "Periodic Hyprland session task";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [
        config.programs.hyprland.package
        pkgs.jq
        pkgs.procps
        pkgs.gawk
        "/run/current-system/sw"
      ];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "hyprland-session-restore";
        ExecStart = "${pkgs.bash}/bin/bash ${scripts}/onTimer.sh";
      };
    };

    systemd.user.timers.hyprland-session-restore-timer = {
      wantedBy = [ "hyprland-session-restore.service" ];
      partOf = [ "graphical-session.target" ];
      timerConfig = {
        OnActiveSec = "2min";
        OnUnitActiveSec = "2min";
      };
    };
  };
}
