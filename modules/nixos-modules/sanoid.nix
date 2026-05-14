{ ... }:
{
  services.sanoid = {
    enable = true;
    interval = "hourly";

    templates.critical = {
      hourly = 50;
      daily = 15;
      weekly = 3;
      monthly = 1;
      autoprune = true;
      autosnap = true;
    };

    templates.important = {
      hourly = 24;
      daily = 7;
      weekly = 2;
      monthly = 1;
      autoprune = true;
      autosnap = true;
    };

    templates.standard = {
      hourly = 12;
      daily = 3;
      weekly = 1;
      autoprune = true;
      autosnap = true;
    };
  };
}
