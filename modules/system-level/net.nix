{ config, lib, ... }:
{
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = config.mySystem.hostName;
    networkmanager = {
      enable = true;
      # DHCP handed out a new address after every link flap, orphaning sessions bound to the old one
      ensureProfiles.profiles.enp5s0-static = {
        connection = {
          id = "enp5s0-static";
          type = "ethernet";
          interface-name = "enp5s0";
          # outranks the generated "Wired connection 1" at -999 on the same device
          autoconnect-priority = 100;
        };
        ipv4 = {
          method = "manual";
          address1 = "192.168.88.5/24,192.168.88.1";
          dns = "192.168.88.1;";
        };
        ipv6.method = "auto";
      };
    };
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
