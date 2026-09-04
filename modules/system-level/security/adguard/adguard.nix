{ config, lib, ... }:
let
  # libvirt's dnsmasq holds 192.168.122.1:53 and 192.168.126.1:53, so a wildcard bind collides
  tsIPv4 = "100.81.141.83";
  tsIPv6 = "fd7a:115c:a1e0::8f39:8d53";
  dnscrypt = "127.0.0.1:5300";
in
{
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    # firewall trusts only tailscale0, so binding wide stays tailnet-only
    host = "0.0.0.0";
    port = 3000;

    settings = {
      dns = {
        bind_hosts = [
          "127.0.0.1"
          "::1"
          tsIPv4
          tsIPv6
        ];
        port = 53;
        upstream_dns = [ dnscrypt ];
        bootstrap_dns = [ dnscrypt ];
        # the 20qps default buckets clients by /24 and throttles a whole device under a browser burst
        ratelimit = 0;
        # an empty local_ptr_upstreams falls back to the OS resolver, which points back at this daemon
        use_private_ptr_resolvers = false;
        cache_optimistic = true;
        serve_plain_dns = true;
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        filters_update_interval = 24;
      };

      # the 90-day default grows unbounded once the whole tailnet resolves through here
      querylog = {
        enabled = true;
        file_enabled = true;
        interval = "168h";
      };

      statistics = {
        enabled = true;
        interval = "168h";
      };

      # yaml-merge replaces lists wholesale, so this file is authoritative; `block-s` round-trips it
      filters = builtins.fromJSON (builtins.readFile ./filters.json);
    };
  };

  # bind_hosts names the tailscale IP, which does not exist until the interface is up
  systemd.services.adguardhome = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    # "+" escapes the sandbox; without AF_UNIX the LocalAPI socket is unreachable and the wait hangs
    serviceConfig.ExecStartPre = [
      "+${lib.getExe config.services.tailscale.package} wait"
    ];
  };

  # DynamicUser puts StateDirectory under private/, and the tmpfs root would drop it every boot
  preservation.preserveAt."/persist".directories = [ "/var/lib/private/AdGuardHome" ];
}
