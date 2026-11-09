{ pkgs, ... }:

{
  xdg.desktopEntries.herdr = {
    categories = [
      "Development"
      "ConsoleOnly"
    ];
    exec = "kitty --class herdr -- herdr";
    genericName = "Multiplexer";
    name = "Herdr";
    icon = "kitty";
    settings.StartupWMClass = "herdr";
    terminal = false;
  };

  xdg.desktopEntries.nvim =
    let
      nvim-zi = pkgs.writeShellScript "nvim-zi" ''
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
      exec = "kitty --class nvim -- ${nvim-zi}";
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
    exec = "kitty --class yazi -- yazi";
    genericName = "File Manager";
    name = "Yazi";
    icon = "kitty";
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
    exec = "kitty --class vtop -- vtop";
    genericName = "System Monitor";
    name = "Vtop";
    icon = "kitty";
    settings.StartupWMClass = "vtop";
    terminal = false;
  };

  xdg.desktopEntries.vimnm = {
    categories = [
      "Network"
      "ConsoleOnly"
    ];
    exec = "kitty --class vimnm -- vimnm";
    genericName = "Wlan Manager";
    name = "Vimnm";
    icon = "kitty";
    settings.StartupWMClass = "vimnm";
    terminal = false;
  };
}
