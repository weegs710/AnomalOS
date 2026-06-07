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

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
      Restart = "on-failure";
    };
  };

  hjem.users.${username}.xdg.config.files."kdeconnect/config".text = ''
    [General]
    customDevices=['100.121.71.20']
    keyAlgorithm=EC
    name=${config.networking.hostName}
  '';

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/kdeconnect"
  ];
}
