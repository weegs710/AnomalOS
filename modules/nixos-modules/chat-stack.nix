{ ... }:
{
  services.bitlbee = {
    enable = true;
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/private/bitlbee";
      mode = "0700";
    }
  ];
}
