{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.tmux ];

  my.links.".tmux.conf" = "tmux/.tmux.conf";
}
