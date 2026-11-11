{ pkgs, ... }:

let
  terminal = "kitty";
in

{
  xdg.desktopEntries.herdr = {
    categories = [
      "Development"
      "ConsoleOnly"
    ];
    exec = "${terminal} --class herdr -- herdr";
    genericName = "Multiplexer";
    name = "Herdr";
    icon = terminal;
    settings.StartupWMClass = "herdr";
    terminal = false;
  };

  xdg.desktopEntries.nvim =
    let
      nvim-zi = pkgs.writeShellScript "nvim-zi" ''
        # Opened with files (xdg-open, file manager): just edit them
        if [ "$#" -gt 0 ]; then
          exec nvim "$@"
        fi

        # Launched from an app launcher: pick a directory with zoxide
        dir=$(zoxide query -i) && cd "$dir"
        exec nvim "''${dir:-.}"
      '';
    in
    {
      categories = [
        "Development"
        "IDE"
        "TextEditor"
        "ConsoleOnly"
      ];
      exec = "${terminal} --class nvim -- ${nvim-zi} %F";
      genericName = "Text Editor";
      name = "Neovim";
      icon = "nvim";
      settings.StartupWMClass = "nvim";
      terminal = false;
    };

  xdg.desktopEntries.yazi = {
    categories = [
      "System"
      "FileManager"
      "ConsoleOnly"
    ];
    exec = "${terminal} --class yazi -- yazi";
    genericName = "File Manager";
    name = "Yazi";
    icon = terminal;
    settings.StartupWMClass = "yazi";
    terminal = false;
  };

  xdg.desktopEntries.vtop = {
    categories = [
      "System"
      "Utility"
      "Monitor"
      "ConsoleOnly"
    ];
    exec = "${terminal} --class vtop -- vtop";
    genericName = "System Monitor";
    name = "Vtop";
    icon = terminal;
    settings.StartupWMClass = "vtop";
    terminal = false;
  };

  xdg.desktopEntries.vimnm = {
    categories = [
      "Network"
      "ConsoleOnly"
    ];
    exec = "${terminal} --class vimnm -- vimnm";
    genericName = "Wlan Manager";
    name = "Vimnm";
    icon = terminal;
    settings.StartupWMClass = "vimnm";
    terminal = false;
  };

  xdg.desktopEntries.superfile = {
    categories = [
      "System"
      "FileTools"
      "FileManager"
      "ConsoleOnly"
    ];
    exec = "${terminal} --class superfile -- superfile %F";
    genericName = "File Manager";
    name = "superfile";
    icon = "system-file-manager";
    settings.StartupWMClass = "superfile";
    terminal = false;
    mimeType = [ "inode/directory" ];
  };

  xdg.desktopEntries.rmpc = {
    categories = [
      "Audio"
      "Music"
      "Player"
      "ConsoleOnly"
    ];
    exec = "${terminal} --class rmpc -- rmpc";
    genericName = "Music Player Interface";
    name = "Rmpc";
    icon = terminal;
    settings.StartupWMClass = "rmpc";
    terminal = false;
  };

}
