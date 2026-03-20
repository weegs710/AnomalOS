{
  flake.nixosModules.tailscale = {config, ...}: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.age.secrets.tailscale-authkey.path;
    };
    networking.firewall.trustedInterfaces = ["tailscale0"];
  };
}
