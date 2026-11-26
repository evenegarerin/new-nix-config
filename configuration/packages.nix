{ pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      file
      gnote
      glib
      lowfi
      spotify
      wev
      mp3gain
      evtest
      pass
      prettier
      resonance
      blueman
      ruff
      ripgrep
      fd
      mission-center
      # nwg-displays
      # nwg-look
      devenv
      playerctl
      wlrctl
      nemo
      xev
      showmethekey
      keypunch
      appflowy
      devtoolbox
      jq
      pulseaudio
      brightnessctl
      bluez
      llmfit
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
      # wofi
      # ulauncher
      # qutebrowser
      # claude-code
      gnome-text-editor
      chromium
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
      nixd
      lua-language-server
      stylua
      shfmt
      taplo
      qt6.qtdeclarative
      typescript-language-server
      vscode-langservers-extracted
      bash-language-server
      yaml-language-server
      marksman
      pyright
      texlab
      # wlr-randr
      # usbutils
      grim
      lazygit
      lazydocker
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
      posting
      udiskie
      nvd
    ])
    ++ (with pkgs-unstable; [
    ]);
}
