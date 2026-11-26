{ pkgs-unstable, ... }:

{
  environment.systemPackages = [ pkgs-unstable.herdr ];

  system.userActivationScripts.herdrClaudeIntegration = ''
    ${pkgs-unstable.herdr}/bin/herdr integration install claude || true
  '';

  my.links.".config/herdr/config.toml" = "herdr/config.toml";
}
