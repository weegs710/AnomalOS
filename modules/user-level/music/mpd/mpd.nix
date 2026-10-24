{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  # mpd-mpris stays out of the profile: its XDG autostart entry dials :6600 while mpd listens only on the socket, so it fails every login
  users.users.${username}.packages = [
    pkgs.mpd
  ];

  hjem.users.${username} = {
    xdg.config.files."mpd/mpd.conf".text = lib.replaceStrings [ "@USER@" ] [ username ] (
      builtins.readFile ./mpd.conf
    );

    systemd.services.mpd = {
      description = "Music Player Daemon";
      documentation = [
        "man:mpd(1)"
        "man:mpd.conf(5)"
      ];
      after = [
        "network.target"
        "sound.target"
      ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon /home/${username}/.config/mpd/mpd.conf";
        Restart = "on-failure";
        RestartSec = 5;
        ProtectSystem = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
      };
    };

    systemd.services.mpd-mpris = {
      description = "MPRIS2 bridge for MPD";
      after = [ "mpd.service" ];
      wantedBy = [ "default.target" ];
      environment = {
        MPD_HOST = "/home/${username}/.config/mpd/socket";
      };
      serviceConfig = {
        ExecStart = "${pkgs.mpd-mpris}/bin/mpd-mpris";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${username}/.local/share/mpd 0755 ${username} users -"
  ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/mpd"
  ];
}
