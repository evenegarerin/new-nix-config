{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
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
        command = "Hyprland";
        user = "castle";
      };
    };
  };

  programs.zsh.enable = true;

  programs.hyprland.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;

  services.blueman.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      53317 # localsend
    ];
  };

  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    kitty
    file
    waybar
    gnote
    glib
    andromeda-gtk-theme
    gedit
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
    hyprlauncher
    elm-land
    typescript
    wl-clipboard
    wl-clip-persist
    datasette
    sqlite-utils
    localsend
    polkit
    polkit_gnome
    postman
    qalculate-gtk
  ];

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
    ];
  };

  users.users.admin = {
    initialPassword = "password"; # remember to change using "passwd"
    isNormalUser = true;
    description = "admin";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
    ];
  };

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
        home.stateVersion = "25.11";

        imports =
          let
            dir = ./home;
            files = builtins.readDir dir;
          in
          builtins.map (name: dir + ("/" + name)) (
            builtins.filter (name: files.${name} == "regular" && builtins.match ".*\\.nix" name != null) (
              builtins.attrNames files
            )
          );
      };

    users.admin =
      { pkgs, ... }:
      {
        home.stateVersion = "25.11";

        imports = [
          ./home/zsh.nix
        ];
      };
  };

  system.stateVersion = "25.11";
}
