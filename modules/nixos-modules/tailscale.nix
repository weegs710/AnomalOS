{
  flake.nixosModules.tailscale = {...}: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = ["tailscale0"];
  };
}
