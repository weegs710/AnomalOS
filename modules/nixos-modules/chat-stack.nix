{ pkgs, ... }:
{
  services.bitlbee = {
    enable = true;
    plugins = [ pkgs.bitlbee-steam ];
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/private/bitlbee";
      mode = "0700";
    }
  ];
}
