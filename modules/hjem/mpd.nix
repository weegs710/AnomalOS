{
  flake.nixosModules.mpd =
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
        pkgs.mpd
        pkgs.mpd-mpris
      ];

      hjem.users.${username} = {
        xdg.config.files."mpd/mpd.conf".text = ''
          music_directory    "/home/${username}/Music"
          playlist_directory "/home/${username}/Music/playlists"
          bind_to_address    "/home/${username}/.config/mpd/socket"

          db_file            "/home/${username}/.local/share/mpd/database"
          state_file         "/home/${username}/.local/share/mpd/state"
          sticker_file       "/home/${username}/.local/share/mpd/sticker.sql"
          pid_file           "/home/${username}/.local/share/mpd/pid"

          audio_output {
            type "pipewire"
            name "PipeWire Sound Server"
          }
        '';
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
        serviceConfig = {
          ExecStart = "${pkgs.mpd-mpris}/bin/mpd-mpris";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      systemd.tmpfiles.rules = [
        "d /home/${username}/.local/share/mpd 0755 ${username} users -"
      ];
    };
}
