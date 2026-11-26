{ config, lib, pkgs, ... }:

let
  terminal = "kitty";

  tuiApp = lib.types.submodule (
    { name, ... }:
    {
      options = {
        desktopName = lib.mkOption {
          type = lib.types.str;
          description = "Name shown in launchers.";
        };
        genericName = lib.mkOption {
          type = lib.types.str;
          description = "Generic description such as File Manager.";
        };
        categories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Desktop entry categories; ConsoleOnly is added automatically.";
        };
        command = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Command run inside the terminal.";
        };
        icon = lib.mkOption {
          type = lib.types.str;
          default = terminal;
          description = "Icon name.";
        };
        mimeTypes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "MIME types the entry can open.";
        };
      };
    }
  );

  tui =
    name: app:
    lib.hiPrio (pkgs.makeDesktopItem {
      inherit name;
      inherit (app)
        desktopName
        genericName
        icon
        mimeTypes
        ;
      categories = app.categories ++ [ "ConsoleOnly" ];
      exec = "${terminal} --class ${name} -- ${app.command}";
      startupWMClass = name;
      terminal = false;
    });
in

{
  options.my.tuiApps = lib.mkOption {
    type = lib.types.attrsOf tuiApp;
    default = { };
    description = "Terminal programs that get a desktop entry opening them in ${terminal}, keyed by the entry and window class name.";
  };

  config = {
    environment.systemPackages = lib.mapAttrsToList tui config.my.tuiApps;
  };
}
