{config, ...}: {
  # Network configuration - always enabled (core system feature)
  # Includes: NetworkManager, firewall, hostname, timezone

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
