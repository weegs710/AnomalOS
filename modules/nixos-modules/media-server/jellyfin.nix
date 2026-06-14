{
  config,
  ...
}:
{
  services.jellyfin = {
    enable = true;
    group = "media";
    openFirewall = false;
    # keep cache inside the persisted data dir -- /var/cache is on 256MB tmpfs
    cacheDir = "/var/lib/jellyfin/cache";
  };

  # render/video needed for VAAPI access to /dev/dri/renderD128
  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];

  # the 700 home dir blocks jellyfin from reaching ~/Music directly
  fileSystems."/mnt/media/music" = {
    device = "/persist/home/${config.mySystem.user.name}/Music";
    fsType = "none";
    options = [
      "bind"
      "ro"
    ];
  };

  # Jellyfin has no reason to write to the media library; transcoding cache stays in /var/lib/jellyfin
  systemd.services.jellyfin.serviceConfig.ReadOnlyPaths = [
    "/mnt/media/movies"
    "/mnt/media/tv"
    "/mnt/media/music"
  ];

  # only Jellyfin hits the LAN; management UIs stay localhost-only
  networking.firewall.allowedTCPPorts = [ 8096 ];

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/jellyfin";
      user = "jellyfin";
      group = "media";
      mode = "0755";
    }
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".local/share/zen-jellyfin"
  ];
}
