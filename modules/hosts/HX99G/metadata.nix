{
  system = "x86_64-linux";
  # ZFS reads this from /etc/hostid to refuse importing a pool owned by another machine, so it must differ per host
  hostId = "fff29759";
  tags = [
    "desktop"
    "dev"
    "gaming"
    "lab"
    "server"
  ];
}
