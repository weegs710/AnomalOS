{ lib, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [
      2222
      8080
      1337
      4000 # Median XL Sigma LAN host (TCP/IP games)
    ]
    ++ (lib.range 23243 23262);
    allowedUDPPorts = [
      23253
      23243
    ];
  };
}
