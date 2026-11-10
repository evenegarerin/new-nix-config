{ lib, pkgs-unstable, ... }:

{
  home.activation.herdrClaudeIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs-unstable.herdr}/bin/herdr integration install claude
  '';
}
