{config, ...}: {
  networking = {
    hostName = config.mySystem.hostName;
    hostId = "fff29759";
    networkmanager.enable = true;
    nftables.enable = true;

    firewall = {
      enable = true;
      allowPing = false;
      trustedInterfaces = ["virbr0"];
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  time.timeZone = config.mySystem.timeZone;
}
