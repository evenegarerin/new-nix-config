{ ... }:

{
  networking.hostName = "thinkpad";

  networking.networkmanager.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      53317 # localsend
    ];
  };
}
