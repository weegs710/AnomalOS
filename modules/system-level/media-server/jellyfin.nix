{
  config,
  pkgs,
  ...
}:
let
  ffmpegFix =
    commit: hash:
    pkgs.fetchpatch2 {
      # code.ffmpeg.org's patch output has drifted under nixpkgs' own hashes (nixpkgs#583143)
      url = "https://github.com/FFmpeg/FFmpeg/commit/${commit}.patch";
      inherit hash;
    };
  # ffmpeg master fixes that no 8.1.x or jellyfin-ffmpeg release carries yet; drop them once one does
  jellyfinFfmpeg = pkgs.jellyfin-ffmpeg.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # CVE-2026-107675
      (ffmpegFix "2b822b7fb6ed195546bc9fd9bdb794e98222bdce" "sha256-QueVBkxML7YelYnJy4kfffONzhN3BuKBfyZxLiOCnH4=")
      # CVE-2026-107676
      (ffmpegFix "2c2f6e96e31795ae95a8f8323a493ffbc493111f" "sha256-B3L0EDuO0nxzyYA1eaELf1OKWCcH1DRGvViqn0REWuE=")
      # CVE-2026-107677
      (ffmpegFix "ed27bfcbbbc0872c0195eaf4dd2c0c93b9f1778e" "sha256-AFPI1yNBhYVwVJtVyaAYtvq6zpk6T2qg0y4BxzVQh7g=")
      (ffmpegFix "403dd2ee396dbafc727fc7bf552ff41233811316" "sha256-gkLDzKbu6GT1eSJnF/HsAfyUsiXSnEeG+eF7kkptS+A=")
      # CVE-2026-107678
      (ffmpegFix "969c7eb091989a664cb7bf66a1f02051cc46cb52" "sha256-0I2tPj0pQEDOt4+S1hYFV+JVyqCmc2YP+9EvpI70fzA=")
      # the APIchanges entry and minor-version bump are master bookkeeping that 8.1 cannot take
      (pkgs.fetchpatch2 {
        url = "https://github.com/FFmpeg/FFmpeg/commit/d1434518fbd03789e3e5dc0657a7a9f1123ce074.patch";
        excludes = [
          "doc/APIchanges"
          "libavutil/version.h"
        ];
        hash = "sha256-DoJ/4qbY2PlrFCVVSLWlO0XLBdzzvSjULUDJ4ZRVOpc=";
      })
      (ffmpegFix "71403a21b02a92b925e26e609e9bd3e48df451cf" "sha256-xPJLJ2Bm8npgEpiOJpvbOqk8+e86JfhmSpwg367lFFo=")
      # CVE-2026-107696
      (ffmpegFix "f5d4fd186c68913240c4f6e9cda98443e1518b34" "sha256-7dSZZkASOtO3vIwXKczf1At0bwGmfRdkJ1MkcJO/pzE=")
    ];
  });
in
{
  services.jellyfin = {
    enable = true;
    package = pkgs.jellyfin.override { jellyfin-ffmpeg = jellyfinFfmpeg; };
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

  # id pinned so allocation order can never reassign the owner of persisted state
  users.users.jellyfin.uid = 997;

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

  # only Jellyfin hits the LAN; the management UIs bind wide but only tailscale0 is trusted
  networking.firewall.allowedTCPPorts = [ 8096 ];

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/jellyfin";
      user = "jellyfin";
      group = "media";
      mode = "0755";
    }
  ];

}
