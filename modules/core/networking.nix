{
  config,
  lib,
  ...
}: {
  networking = {
    hostName = config.mySystem.hostName;
    hostId = "fff29759";
    networkmanager.enable = true;
    nftables.enable = true;

    firewall = {
      enable = true;
      allowPing = false;
      trustedInterfaces = ["virbr0"];
      # Basic ports - specific applications can add their own
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  time.timeZone = config.mySystem.timeZone;
}
