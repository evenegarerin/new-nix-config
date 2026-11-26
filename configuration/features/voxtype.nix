{
  pkgs,
  config,
  ...
}:

let
  user = config.my.user;
  home = config.users.users.${user}.home;
  configDir = "${home}/nix-config/config";
in
{
  environment.systemPackages = with pkgs; [
    voxtype-vulkan
  ];

  systemd.tmpfiles.rules = [
    "d ${home}/.config/voxtype 0755 ${user} users -"
    "L+ ${home}/.config/voxtype/config.toml - - - - ${configDir}/voxtype/config.toml"
  ];
}
