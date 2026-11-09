{ ... }:

{
  # The keyd group and the capability override exist only for this service, so they live with it.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = { };
    };
  };

  users.groups.keyd = { };
  systemd.services.keyd.serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];
}
