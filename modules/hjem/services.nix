{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [
    pkgs.autotrash
    pkgs.udiskie
  ];

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
    wantedBy = [ "timers.target" ];
  };

  systemd.user.targets.tray = {
    description = "System Tray";
    wantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.udiskie = {
    description = "udiskie - automount removable media";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    # udiskie's tray "browse" action shells out to xdg-open, which isn't in the default user-service PATH
    path = [ pkgs.xdg-utils ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
      Restart = "on-failure";
    };
  };
}
