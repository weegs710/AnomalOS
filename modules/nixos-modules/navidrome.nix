{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  services.navidrome = {
    enable = true;
    settings = {
      # 0.0.0.0 needed -- tailscale0 is trusted but 127.0.0.1 won't route tailscale traffic
      Address = "0.0.0.0";
      # ProtectHome blocks /home -- use persist path directly (impermanence source is the same data)
      MusicFolder = "/persist/home/${username}/Music";
      # nix store is bind-mounted into the sandbox; give navidrome the store path directly
      FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
    };
  };

  environment.persistence."/persist".directories = [ "/var/lib/navidrome" ];
}
