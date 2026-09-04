{ config, lib, ... }:
{
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = config.mySystem.hostName;
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
    # "server" is the half that turns on IP forwarding; an exit node cannot route without it
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
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

  systemd.services.searx-tailscale-serve = {
    description = "Tailscale Serve HTTPS in front of searxng :8888";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # After= only waits for the unit; serve needs the backend Running or it exits on NoState.
      ExecStartPre = "${lib.getExe config.services.tailscale.package} wait";
      ExecStart = "${lib.getExe config.services.tailscale.package} serve --bg 8888";
    };
  };
}
