{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    home-manager.users.${config.mySystem.user.name} = {
      home.packages = [pkgs.autotrash];

      systemd.user.services.autotrash = {
        Unit = {
          Description = "Autotrash - automatic trash cleanup";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.autotrash}/bin/autotrash --days 30 --trash_limit 10240";
        };
      };

      systemd.user.timers.autotrash = {
        Unit = {
          Description = "Run autotrash daily";
        };
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };
    };
  };
}
