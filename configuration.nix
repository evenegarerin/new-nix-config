{ ... }:
{
  imports = [
    ./configuration/audio.nix
    ./configuration/desktop.nix
    ./configuration/firefox.nix
    ./configuration/hardware.nix
    ./configuration/keyd.nix
    ./configuration/locale.nix
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

  system.stateVersion = "25.11";
}
