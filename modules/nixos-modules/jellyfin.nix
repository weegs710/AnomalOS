{
  flake.nixosModules.jellyfin = {
    ...
  }: {
    services.jellyfin = {
      enable = true;
      group = "media";
      openFirewall = false;
      # keep cache inside the persisted data dir -- /var/cache is on 256MB tmpfs
      cacheDir = "/var/lib/jellyfin/cache";
    };

    # render/video needed for VAAPI access to /dev/dri/renderD128
    users.users.jellyfin.extraGroups = ["render" "video"];

    # Jellyfin has no reason to write to the media library; transcoding cache stays in /var/lib/jellyfin
    systemd.services.jellyfin.serviceConfig.ReadOnlyPaths = [
      "/mnt/media/movies"
      "/mnt/media/tv"
    ];

    # only Jellyfin hits the LAN; management UIs stay localhost-only
    networking.firewall.allowedTCPPorts = [8096];

    environment.persistence."/persist".directories = ["/var/lib/jellyfin"];
  };
}
