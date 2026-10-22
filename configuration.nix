{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = false;

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev"; # important for UEFI

  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thinkpad";

  security.sudo.extraConfig = ''
    Defaults rootpw
  '';

  security.polkit.adminIdentities = [ "unix-user:0" ];

  hardware.i2c.enable = true;

  services.tlp = {
    enable = true;

    settings = {
      STOP_CHARGE_THRESH_BAT0 = 95;
      START_CHARGE_THRESH_BAT0 = 80;
    };
  };

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  security.polkit.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "castle";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "history" "command-not-found" ];
      theme = "af-magic";
    };
  };

  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;
  programs.direnv.enable = true;

  services.blueman.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      53317 # localsend
    ];
  };

  virtualisation.libvirtd.enable = true;

  virtualisation.docker.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = [ "*" ];

      # Hold Strg+Alt to reach the AltGr level, Windows-style.
      settings."control+alt" = {
        "7" = "G-7";                                              # {
        "8" = "G-8";                                              # [
        "9" = "G-9";                                              # ]
        "0" = "G-0";                                              # }
        minus = "G-minus";                                        # ß -> \
        rightbrace = "G-rightbrace";                              # + -> ~
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  services.elephant.enable = true;

  systemd.user.services.elephant.enableDefaultPath = false;

  environment.systemPackages = with pkgs; [
    kitty
    file
    waybar
    gnote
    glib
    andromeda-gtk-theme
    lowfi
    spotify
    wev
    mp3gain
    evtest
    pcmanfm
    pass
    resonance
    blueman
    ruff
    ripgrep
    fd
    imv
    polkit_gnome
    mission-center
    nwg-displays
    nwg-look
    playerctl
    hyprcursor
    nemo
    xev
    keypunch
    appflowy
    devtoolbox
    jq
    pulseaudio
    brightnessctl
    bluez
    pnpm
    nodejs
    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        dbus-python
        standard-imghdr
        numpy
        python-lsp-server
        python-lsp-ruff
        pynvim
      ]
    ))
    nixfmt
    git
    fzf
    networkmanagerapplet
    hyprpolkitagent
    hyprpaper
    elmPackages.elm-format
    elmPackages.elm-language-server
    elmPackages.elm
    elmPackages.elm-review
    elm-land
    typescript
    wl-clipboard
    wl-clip-persist
    sqlite-utils
    localsend
    polkit
    polkit_gnome
    postman
    gnome-calculator
    # qalculate-gtk
    yazi
    wofi
    ulauncher
    walker
    qutebrowser
    hyprlock
    hypridle
    firefox
    vscodium
    claude-code
    gnupg
    pinentry-tty
    gnome-text-editor
    chromium
    tmux
    just
    bubblewrap
    nftables
    # passt
    psmisc
    openbao
    # steam
    papirus-icon-theme
    kdePackages.filelight
    pinta
    blender
    # ddcutil
    neovim
    # wlr-randr
    # usbutils
    grim
    lazygit
    herdr
    secretspec
    docker
    jdk25
    gradle_9
  ];

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "Andromeda";
          color-scheme = "prefer-dark";
          monospace-font-name = "JetBrainsMono Nerd Font";
          icon-theme = "Papirus-Dark";
        };
        "org/gnome/TextEditor" = {
          auto-indent = true;
          show-line-numbers = true;
          highlight-current-line = true;
          spellcheck = false;
          tab-width = lib.gvariant.mkUint32 4;
          use-system-font = true;
          wrap-text = true;
        };
      };
    }];
  };

  environment.etc."firefox/policies/policies.json".source =
    ./config/firefox/policies.json;

  environment.pathsToLink = [
    "/share/glib-2.0/schemas"
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    plus-jakarta-sans
  ];

  xdg.portal = {
    enable = true;

    config = {
      common = {
        default = "gtk";
      };
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  environment.etc."xdg/kdeglobals".source = pkgs.runCommand "kdeglobals" { } ''
    cat ${pkgs.dracula-theme}/share/color-schemes/Dracula.colors > $out
  '';

  console.keyMap = "de";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.castle = {
    initialPassword = "password"; # remember to change using "passwd"
    isNormalUser = true;
    description = "castle";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
    ];
  };

  users.users.root.initialPassword = "password"; # change this!!!

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit inputs;
    };

    backupFileExtension = "backup";

    users.castle =
      { pkgs, inputs, ... }:
      {
        home.stateVersion = "26.05";

        imports = [ ./home.nix ];
      };
  };

  system.stateVersion = "26.05";
}
