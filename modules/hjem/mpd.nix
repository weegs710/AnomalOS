{
  flake.nixosModules.mpd = {
    config,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    # Skip password lookup when no secret service is running
    # See: https://github.com/htkhiem/euphonica/pull/267
    euphonica = pkgs.euphonica.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/euphonica-fix-no-secret-service];
    });
  in {
    users.users.${username}.packages = [
      euphonica
      pkgs.mpd
    ];

    hjem.users.${username} = {
      xdg.config.files."mpd/mpd.conf".text = ''
        music_directory    "/home/${username}/Music"
        playlist_directory "/home/${username}/Music/playlists"

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
      documentation = ["man:mpd(1)" "man:mpd.conf(5)"];
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];

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

    # Create the MPD state directory
    systemd.tmpfiles.rules = [
      "d /home/${username}/.local/share/mpd 0755 ${username} users -"
    ];
  };
}
