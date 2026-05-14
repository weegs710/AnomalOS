{
  flake.nixosModules.media-stack = {
    config,
    lib,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    users.groups.media = {};
    users.users.${username}.extraGroups = ["media"];

    fileSystems."/mnt/media" = {
      device = "zgames/media";
      fsType = "zfs";
    };

    # setgid bits ensure new files inherit media group across services
    systemd.tmpfiles.rules = [
      "d /mnt/media                2775 root  media - -"
      "d /mnt/media/torrents       2775 root  media - -"
      "d /mnt/media/torrents/movies 2775 root  media - -"
      "d /mnt/media/torrents/tv    2775 root  media - -"
      "d /mnt/media/movies         2775 root  media - -"
      "d /mnt/media/tv             2775 root  media - -"
      # radarr uses nested dataDir (/var/lib/radarr/.config/Radarr); its module only targets
      # the leaf, leaving intermediate dirs root-owned when impermanence bind-mounts them first
      "d /var/lib/radarr           0755 radarr media - -"
      "d /var/lib/radarr/.config   0755 radarr media - -"
    ];

    services.radarr = {
      enable = true;
      group = "media";
      openFirewall = false;
    };

    services.sonarr = {
      enable = true;
      group = "media";
      openFirewall = false;
    };

    services.prowlarr = {
      enable = true;
      openFirewall = false;
      # DynamicUser -- cannot set group; state lands in /var/lib/private/prowlarr
    };

    services.bazarr = {
      enable = true;
      group = "media";
      openFirewall = false;
    };

    environment.persistence."/persist".directories = [
      "/var/lib/radarr"
      "/var/lib/sonarr"
      "/var/lib/bazarr"
      "/var/lib/private/prowlarr"
    ];
  };
}
