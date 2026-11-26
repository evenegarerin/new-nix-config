{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-tty
  ];

  my.links.".gnupg/gpg-agent.conf" = "gnupg/gpg-agent.conf";
  my.dirs.".gnupg" = "0700";
}
