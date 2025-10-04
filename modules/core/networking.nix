{ config, lib, ... }:

{
  networking = {
    hostName = config.mySystem.hostName;
    networkmanager.enable = true;
    nftables.enable = true;

    firewall = {
      enable = true;
      allowPing = false;
      # Basic ports - specific applications can add their own
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  time.timeZone = config.mySystem.timeZone;
}
