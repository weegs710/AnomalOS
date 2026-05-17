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

    # templates.<name> = {
    #   hourly = <hourlies to keep>;
    #   daily = <dailies to keep>;
    #   weekly = <weeklies to keep>;
    #   monthly = <monthlies to keep>;
    #   autoprune = true; # delete snapshots beyond the counts above
    #   autosnap = true; # take snapshots on the sanoid interval
    # };
  };
}
