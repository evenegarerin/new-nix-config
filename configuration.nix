{ ... }:
{
  imports = [
    ./configuration/audio.nix
    ./configuration/auto-upgrade.nix
    ./configuration/config-links.nix
    ./configuration/desktop-files.nix
    ./configuration/desktop.nix
    ./configuration/hardware.nix
    ./configuration/home.nix
    ./configuration/locale.nix
    ./configuration/mime-apps.nix
    ./configuration/networking.nix
    ./configuration/packages.nix
    ./configuration/shell.nix
    ./configuration/theming.nix
    ./configuration/users.nix
    ./configuration/virtualisation.nix
    ./configuration/features/claude.nix
    ./configuration/features/espanso.nix
    ./configuration/features/firefox.nix
    ./configuration/features/gnupg.nix
    ./configuration/features/herdr.nix
    ./configuration/features/hyprland.nix
    ./configuration/features/keyd.nix
    ./configuration/features/kitty.nix
    ./configuration/features/neovim.nix
    ./configuration/features/pcmanfm.nix
    ./configuration/features/quickshell.nix
    ./configuration/features/qutebrowser.nix
    ./configuration/features/starship.nix
    ./configuration/features/superfile.nix
    ./configuration/features/swaync.nix
    ./configuration/features/tmux.nix
    ./configuration/features/voxtype.nix
    ./configuration/features/vscodium.nix
    ./configuration/features/walker.nix
    ./configuration/features/waybar.nix
    ./configuration/features/yazi.nix
    ./configuration/features/zsh.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
