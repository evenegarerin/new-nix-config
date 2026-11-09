{
  config,
  lib,
  pkgs,
  ...
}:

let
  configDir = "${config.home.homeDirectory}/nix-config/config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${configDir}/${path}";
in
{
  home.pointerCursor = {
    enable = true;

    package = pkgs.borealis-cursors;
    name = "Borealis-cursors";
    size = 24;

    hyprcursor.enable = true;
    gtk.enable = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    desktop = "$HOME/Desktop";
  };

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

  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      isDefault = true;
    };
  };

  xdg.configFile =
    # Directories that share the same name in this configuration and in ~/.config
    lib.genAttrs
      [
        "elephant"
        "gtk-3.0"
        "gtk-4.0"
        "hypr"
        "kitty"
        "nvim"
        "qutebrowser"
        "swaync"
        "waybar"
        "yazi"
        "wallpapers"
        "pcmanfm"
        "walker"
        "quickshell"
      ]
      (name: {
        source = link name;
      })
    // {
      "VSCodium/User/settings.json".source = link "vscodium/settings.json";
      "herdr/config.toml".source = link "herdr/config.toml";
      "keyd/app.conf".source = link "keyd/app.conf";
    };

  home.file = {
    ".zshrc".source = link "zsh/.zshrc";
    ".tmux.conf".source = link "tmux/.tmux.conf";
    ".gnupg/gpg-agent.conf".source = link "gnupg/gpg-agent.conf";
    ".claude/keybindings.json".source = link "claude/keybindings.json";
    ".claude/statusline.sh".source = link "claude/statusline.sh";
    "${config.programs.firefox.configPath}/${config.programs.firefox.profiles.default.path}/chrome".source =
      link "firefox/chrome";
  };
}
