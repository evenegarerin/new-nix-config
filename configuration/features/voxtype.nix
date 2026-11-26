{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    voxtype-vulkan
  ];

  my.links.".config/voxtype/config.toml" = "voxtype/config.toml";
}
