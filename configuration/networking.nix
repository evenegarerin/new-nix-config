{ ... }:

{
  networking.hostName = "thinkpad";

  networking.networkmanager.enable = true;

  networking.networkmanager.connectionConfig = {
    "ipv6.dns-priority" = 90;
  };

  networking.resolvconf.extraOptions = [
    "timeout:1"
    "attempts:2"
  ];

  networking.firewall = {
    allowedTCPPorts = [
      53317 # localsend
    ];
    allowedUDPPorts = [
      53317 # localsend
    ];
  };
}
