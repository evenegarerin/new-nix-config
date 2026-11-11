{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:

let
  user = config.my.user;
in

{
  options.my.user = lib.mkOption {
    type = lib.types.str;
    description = "Primary user of this machine.";
  };

  config = {
    my.user = "castle";

    # Accounts and how they authenticate, plus the home-manager entry point.
    users.users.${user} = {
      uid = 1000;
      initialPassword = "password"; # remember to change using "passwd"
      isNormalUser = true;
      description = user;
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

      users.${user} =
        { pkgs, inputs, ... }:
        {
          home.stateVersion = "26.05";

          imports = [ ../home.nix ];
        };
    };
  };
}
