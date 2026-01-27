{...}: {
  flake.nixosModules.mpd = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      username = config.mySystem.user.name;
    in {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${username} = {
          home.packages = [pkgs.euphonica];

          services.mpd = {
            enable = true;
            musicDirectory = "/home/${username}/Music";
            playlistDirectory = "/home/${username}/Music/playlists";
            extraConfig = ''
              audio_output {
                type "pipewire"
                name "PipeWire Sound Server"
              }
            '';
          };
        };
      };
    };
}
