{ pkgs-unstable, ... }:

{
  environment.systemPackages = [ pkgs-unstable.quickshell ];

  my.links.".config/quickshell" = "quickshell";
}
