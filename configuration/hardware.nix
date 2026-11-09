{ ... }:

{
  # ThinkPad-specific: boot loader, buses, radios, and battery charge thresholds.
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = false;

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev"; # important for UEFI

  boot.loader.efi.canTouchEfiVariables = true;

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
