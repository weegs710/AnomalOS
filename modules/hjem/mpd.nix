{
  flake.nixosModules.mpd = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    deezerSrc = ./euphonica-deezer;
    euphonica-with-deezer = pkgs.euphonica.overrideAttrs (old: {
      prePatch = (old.prePatch or "") + ''
        mkdir -p src/meta_providers/deezer
        cp ${deezerSrc}/mod.rs src/meta_providers/deezer/mod.rs
        cp ${deezerSrc}/models.rs src/meta_providers/deezer/models.rs
        cp ${deezerSrc}/controller.rs src/meta_providers/deezer/controller.rs
      '';
      patches = (old.patches or []) ++ [ "${deezerSrc}/add-deezer-provider" ];
    });
  in {
    config = lib.mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [
          euphonica-with-deezer
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
    };
}
