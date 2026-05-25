{
  config,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.groups.media = { };
  users.users.${username}.extraGroups = [ "media" ];

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
    # radarr uses nested dataDir (/var/lib/radarr/.config/Radarr); intermediate dirs need explicit ownership
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
  };

  # DynamicUser conflicts with preservation bind-mounts -- chowns fail on already-mounted dirs
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    home = "/var/lib/prowlarr";
  };
  users.groups.prowlarr = { };

  systemd.services.prowlarr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    StateDirectory = lib.mkForce "";
    User = lib.mkForce "prowlarr";
    Group = lib.mkForce "prowlarr";
    ExecStart = lib.mkForce "${config.services.prowlarr.package}/bin/Prowlarr -nobrowser -data=/var/lib/prowlarr";
  };

  services.bazarr = {
    enable = true;
    group = "media";
    openFirewall = false;
  };

  services.flaresolverr = {
    enable = true;
    # port 8191 default, localhost only -- no openFirewall needed
  };

  # recyclarr v8 schema: no include/template -- uses quality_definition.type,
  # quality_profiles trash_id, and custom_format_groups
  services.recyclarr = {
    enable = true;
    schedule = "weekly";
    configuration = {
      radarr = {
        "hd-bluray-web" = {
          base_url = "http://localhost:7878";
          api_key._secret = config.age.secrets.radarr-api-key.path;
          quality_definition.type = "movie";
          quality_profiles = [
            {
              trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
              reset_unmatched_scores.enabled = true;
            }
          ];
          custom_format_groups.add = [
            {
              trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; # [Unwanted] Unwanted Formats
              select = [
                "b8cd450cbfa689c0259a01d9e29ba3d6" # 3D
                "cae4ca30163749b891686f95532519bd" # AV1
                "ed38b889b31be83fda192888e2286d83" # BR-DISK
                "0a3f082873eb454bde444150b70253cc" # Extras
                "e6886871085226c3da1830830146846c" # Generated Dynamic HDR
                "90a6f9a284dff5103f6346090e6280c8" # LQ
                "e204b80c87be9497a8a6eaff48f72905" # LQ (Release Title)
                "712d74cd88bceb883ee32f773656b1f5" # Sing-Along Versions
                "bfd8eb01832d646a0a89c4deb46f8564" # Upscaled
              ];
            }
          ];
          custom_formats = [
            {
              trash_ids = [ "4a3b087eea2ce012fcc1ce319259a3be" ]; # Anime Dual Audio
              assign_scores_to = [ { name = "HD Bluray + WEB"; score = 10; } ];
            }
          ];
        };
      };
      sonarr = {
        "web-1080p" = {
          base_url = "http://localhost:8989";
          api_key._secret = config.age.secrets.sonarr-api-key.path;
          quality_definition.type = "series";
          quality_profiles = [
            {
              trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
              reset_unmatched_scores.enabled = true;
            }
          ];
          custom_format_groups.add = [
            {
              trash_id = "59c3af66780d08332fdc64e68297098f"; # [Unwanted] Unwanted Formats
              select = [
                "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
                "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                "6f808933a71bd9666531610cb8c059cc" # BR-DISK (BTN)
                "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
                "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                "23297a736ca77c0fc8e70f8edd7ee56c" # Upscaled
              ];
            }
          ];
          custom_formats = [
            {
              trash_ids = [ "418f50b10f1907201b6cfdf881f467b7" ]; # Anime Dual Audio
              assign_scores_to = [ { name = "WEB-1080p"; score = 10; } ];
            }
          ];
        };
      };
    };
  };

  preservation.preserveAt."/persist".directories = [
    "/var/lib/radarr"
    "/var/lib/sonarr"
    { directory = "/var/lib/bazarr"; user = "bazarr"; group = "media"; mode = "0755"; }
    { directory = "/var/lib/prowlarr"; user = "prowlarr"; group = "prowlarr"; mode = "0755"; }
  ];
}
