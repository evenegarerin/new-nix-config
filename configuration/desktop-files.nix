{ pkgs, ... }:

let
  terminal = "kitty";

  nvim-zi = pkgs.writeShellScript "nvim-zi" ''
    if [ "$#" -gt 0 ]; then
      exec nvim "$@"
    fi

    dir=$(zoxide query -i) && cd "$dir"
    exec nvim "''${dir:-.}"
  '';

  tui =
    {
      name,
      desktopName,
      genericName,
      categories,
      command ? name,
      icon ? terminal,
      mimeTypes ? [ ],
    }:
    pkgs.makeDesktopItem {
      inherit
        name
        desktopName
        genericName
        icon
        mimeTypes
        ;
      categories = categories ++ [ "ConsoleOnly" ];
      exec = "${terminal} --class ${name} -- ${command}";
      startupWMClass = name;
      terminal = false;
    };
in

{
  environment.systemPackages = [
    (tui {
      name = "herdr";
      desktopName = "Herdr";
      genericName = "Multiplexer";
      categories = [ "Development" ];
    })
    (tui {
      name = "nvim";
      desktopName = "Neovim";
      genericName = "Text Editor";
      categories = [
        "Development"
        "IDE"
        "TextEditor"
      ];
      command = "${nvim-zi} %F";
      icon = "nvim";
    })
    (tui {
      name = "yazi";
      desktopName = "Yazi";
      genericName = "File Manager";
      categories = [
        "System"
        "FileManager"
      ];
    })
    (tui {
      name = "vtop";
      desktopName = "Vtop";
      genericName = "System Monitor";
      categories = [
        "System"
        "Utility"
        "Monitor"
      ];
    })
    (tui {
      name = "vimnm";
      desktopName = "Vimnm";
      genericName = "Wlan Manager";
      categories = [ "Network" ];
    })
    (tui {
      name = "bluetui";
      desktopName = "Bluetui";
      genericName = "Bluetooth Manager";
      categories = [ "Network" ];
    })
    (tui {
      name = "superfile";
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
    })
    (tui {
      name = "typtea";
      desktopName = "Typtea";
      genericName = "Typing Trainer";
      categories = [ "Game" ];
    })
    (tui {
      name = "rmpc";
      desktopName = "Rmpc";
      genericName = "Music Player Interface";
      categories = [
        "Audio"
        "Music"
        "Player"
      ];
    })
    (tui {
      name = "wiremix";
      desktopName = "Wiremix";
      genericName = "Volume Controller";
      categories = [
        "Audio"
        "Mixer"
      ];
    })
  ];
}
