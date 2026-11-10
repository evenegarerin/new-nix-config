{
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:

{
  # Accounts and how they authenticate, plus the home-manager entry point.
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
      "libvirtd"
      "keyd"
    ];
  };

  users.users.root.initialPassword = "password"; # change this!!!

  security.sudo.extraConfig = ''
    Defaults rootpw, pwfeedback
  '';

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit inputs pkgs-unstable;
    };

    backupFileExtension = "backup";
    overwriteBackup = true;

    users.castle =
      { pkgs, inputs, ... }:
      {
        home.stateVersion = "26.05";

        imports = [ ../home.nix ];
      };
  };
}
