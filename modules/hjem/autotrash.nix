{...}: {
  flake.nixosModules.autotrash = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      username = config.mySystem.user.name;
    in {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [pkgs.autotrash];

        systemd.user.services.autotrash = {
          description = "Autotrash - automatic trash cleanup";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.autotrash}/bin/autotrash --days 30 --trash_limit 10240";
          };
        };

        systemd.user.timers.autotrash = {
          description = "Run autotrash daily";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          wantedBy = ["timers.target"];
        };
      };
    };
}
