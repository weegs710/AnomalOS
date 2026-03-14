{
  flake.nixosModules.dnscrypt = {
    config,
    lib,
    ...
  }: let
    dnsDir = "/var/lib/dnscrypt-proxy";
  in {
    config = {
        networking.nameservers = ["127.0.0.1" "::1"];

        services = {
          resolved.enable = false;
          unbound.enable = false;

          dnscrypt-proxy = {
            enable = true;
            settings = {
              listen_addresses = ["127.0.0.1:53" "[::1]:53"];
              server_names = ["cloudflare" "quad9-dnscrypt-ip4-filter-pri"];
              doh_servers = true;
              require_dnssec = true;
              require_nolog = true;
              require_nofilter = false;
              cache = true;
              cache_size = 4096;
              cache_min_ttl = 2400;
              cache_max_ttl = 86400;
              cache_neg_min_ttl = 60;
              cache_neg_max_ttl = 600;
              block_ipv6 = true;
              sources.public-resolvers = {
                urls = [
                  "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
                  "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
                ];
                cache_file = "${dnsDir}/public-resolvers.md";
                minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
                refresh_delay = 72;
              };
            };
          };
        };
      };
    };
}
