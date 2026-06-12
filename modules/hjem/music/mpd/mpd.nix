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
  users.users.${username}.packages = [
    pkgs.mpd
    pkgs.mpd-mpris
  ];

  hjem.users.${username} = {
    xdg.config.files."mpd/mpd.conf".text = lib.replaceStrings [ "@USER@" ] [ username ] (
      builtins.readFile ./mpd.conf
    );
  };

  # Use NixOS's systemd.user.services instead of trying to create service file via Hjem
  systemd.user.services.mpd = {
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

  systemd.user.services.mpd-mpris = {
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

  systemd.tmpfiles.rules = [
    "d /home/${username}/.local/share/mpd 0755 ${username} users -"
  ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/mpd"
  ];
}
