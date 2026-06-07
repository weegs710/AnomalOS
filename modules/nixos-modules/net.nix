{ config, lib, ... }:
{
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = config.mySystem.hostName;
    hostId = "fff29759";
    networkmanager.enable = true;
    nftables.enable = true;

    firewall = {
      enable = true;
      allowPing = false;
      trustedInterfaces = [
        "virbr0"
        "tailscale0"
      ];
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  time.timeZone = config.mySystem.timeZone;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.age.secrets.tailscale-authkey.path;
  };

  systemd.services.tailscaled = {
    after = lib.mkForce [
      "NetworkManager.service"
      "systemd-resolved.service"
      "network.target"
      "network-pre.target"
    ];
    wants = [ "tailscaled-autoconnect.service" ];
  };

  # multi-user.target infers After= from .wants/ symlinks; removing entry is the only way to unblock
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ];
}
