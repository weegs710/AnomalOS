{ config, lib, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.age.secrets.tailscale-authkey.path;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

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
