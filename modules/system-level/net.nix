{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = config.mySystem.hostName;
    networkmanager.enable = true;
    nftables.enable = true;

    firewall = {
      enable = true;
      allowPing = false;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  time.timeZone = config.mySystem.timeZone;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # the module cats this file into argv, so it holds tailscale's file: reference instead of the key itself
    authKeyFile = pkgs.writeText "tailscale-authkey-ref" "file:${config.age.secrets.tailscale-authkey.path}";
    # an OAuth client secret only mints a key for tagged nodes; ephemeral=false rides inside the secret
    extraUpFlags = [ "--advertise-tags=tag:anomalos" ];
    # "server" is the half that turns on IP forwarding; an exit node cannot route without it
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };

  systemd.services.tailscaled = {
    after = lib.mkForce [
      "NetworkManager.service"
      "network.target"
      "network-pre.target"
    ];
    wants = [ "tailscaled-autoconnect.service" ];
  };

  # multi-user.target infers After= from .wants/ symlinks; removing entry is the only way to unblock
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ];

  preservation.preserveAt."/persist".directories = [
    "/var/lib/tailscale"
    "/etc/NetworkManager/system-connections"
  ];
}
