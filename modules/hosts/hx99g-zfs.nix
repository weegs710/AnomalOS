{ config, ... }:
{
  services.sanoid.datasets = {
    "zroot/persist" = {
      useTemplate = [ "critical" ];
    };
    "zgames/games/roms" = {
      hourly = 6;
      daily = 3;
      weekly = 1;
      autoprune = true;
      autosnap = true;
    };
  };
}
