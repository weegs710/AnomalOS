{ ... }:
{
  services.sanoid = {
    enable = true;
    interval = "hourly";

    # Desktop persist dataset -- active user data, half-day of hourlies is enough to roll back an oopsie
    templates.desktop = {
      hourly = 12;
      daily = 7;
      weekly = 2;
      monthly = 1;
      autoprune = true;
      autosnap = true;
    };
  };
}
