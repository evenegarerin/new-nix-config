{ ... }:

let
  # requires allow-unsafe-native-code-during-evaluation = true
  exec = builtins.getAttr "exec" builtins;
in
{
  # ThinkPad-specific: boot loader, buses, radios, and battery charge thresholds.
  imports = [
    (
      if builtins.pathExists /etc/nixos/hardware-configuration.nix then
        /etc/nixos/hardware-configuration.nix
      else
        exec [
          "nixos-generate-config"
          "--show-hardware-config"
        ]
    )
  ];

  boot.loader.systemd-boot.enable = false;

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev"; # important for UEFI
  boot.loader.grub.configurationLimit = 10;

  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  hardware.i2c.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.tlp = {
    enable = true;

    settings = {
      STOP_CHARGE_THRESH_BAT0 = 95;
      START_CHARGE_THRESH_BAT0 = 80;
    };
  };
}
