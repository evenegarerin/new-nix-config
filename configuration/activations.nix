{ pkgs-unstable, ... }:

{
  system.userActivationScripts.herdrClaudeIntegration = ''
    ${pkgs-unstable.herdr}/bin/herdr integration install claude || true
  '';
}
