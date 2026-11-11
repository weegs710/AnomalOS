{ lib, ... }:
{
  # DHCP handed out a new address after every link flap, orphaning sessions bound to the old one
  networking.networkmanager.ensureProfiles.profiles.enp5s0-static = {
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

  # required by the nixos module assertion; packets are processed in nfq mode (suricata.nix), not af-packet
  services.suricata.settings.af-packet = [
    {
      interface = "enp5s0";
      cluster-id = 99;
      cluster-type = "cluster_flow";
      defrag = true;
    }
  ];

  # libvirt's dnsmasq holds 192.168.122.1:53 and 192.168.126.1:53, so a wildcard bind collides
  services.adguardhome.settings.dns.bind_hosts = lib.mkAfter [
    "100.81.141.83"
    "fd7a:115c:a1e0::8f39:8d53"
  ];

  services.searx.settings.server.base_url = "https://hx99g.tailc3ec2d.ts.net/";
}
