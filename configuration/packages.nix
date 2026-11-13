{ pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      kitty
      file
      waybar
      gnote
      glib
      lowfi
      spotify
      wev
      mp3gain
      evtest
      pcmanfm
      pass
      prettier
      resonance
      blueman
      ruff
      ripgrep
      fd
      imv
      mission-center
      # nwg-displays
      # nwg-look
      playerctl
      hyprcursor
      wlrctl
      keyd
      nemo
      xev
      (callPackage ../selfBuild/vtop.nix { })
      (callPackage ../selfBuild/vimnm.nix { })
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
      cmd-polkit
      postman
      gnome-calculator
      # qalculate-gtk
      yazi
      # wofi
      # ulauncher
      walker
      # qutebrowser
      hyprlock
      hypridle
      vscodium
      # claude-code
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
      kdePackages.filelight
      pinta
      blender
      # ddcutil
      neovim
      nixd
      lua-language-server
      stylua
      shfmt
      taplo
      qt6.qtdeclarative
      typescript-language-server
      bash-language-server
      yaml-language-server
      marksman
      pyright
      texlab
      # wlr-randr
      # usbutils
      grim
      lazygit
      secretspec
      docker
      jdk25
      gradle_9
      rofi
      unzip
      # lazydocker
      pandoc
      (texliveSmall.withPackages (
        ps: with ps; [
          latexmk # vimtex's compiler backend
          tcolorbox # head.tex:23 -- block quote boxes
          newverbs # head.tex:1
          enumitem # head.tex:60 -- 9-deep list nesting
          framed # pandoc's Shaded environment, pulled in by --highlight-style
          # tcolorbox is loaded as [most], which drags in most of its libraries
          pgf
          environ
          tikzfill
          pdfcol
          listings
          listingsutf8
          xurl # optional in pandoc's xelatex template
          selnolig # optional in pandoc's xelatex template
          latexindent
        ]
      ))
      zathura # PDF viewer, SyncTeX source for vimtex
      posting
      udiskie
      swaynotificationcenter
      nvd
      rmpc
      wiremix
    ])
    ++ (with pkgs-unstable; [
      claude-code
      herdr
      hyprshot
      quickshell
      superfile
      hyprmod
    ]);
}
