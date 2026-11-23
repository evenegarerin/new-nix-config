{ ... }:
{
  imports = [
    ./configuration/activations.nix
    ./configuration/audio.nix
    ./configuration/config-links.nix
    ./configuration/desktop.nix
    ./configuration/desktop-files.nix
    ./configuration/firefox.nix
    ./configuration/hardware.nix
    ./configuration/home.nix
    ./configuration/keyd.nix
    ./configuration/locale.nix
    ./configuration/mime-apps.nix
    ./configuration/neovim.nix
    ./configuration/networking.nix
    ./configuration/packages.nix
    ./configuration/shell.nix
    ./configuration/theming.nix
    ./configuration/users.nix
    ./configuration/virtualisation.nix
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
