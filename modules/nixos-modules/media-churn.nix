{
  config,
  pkgs,
  lib,
  ...
}:
let
  python = pkgs.python3.withPackages (ps: [ ps.requests ]);

  churnScript = pkgs.writeText "media-churn.py" ''
    """
    media-churn: delete watched content 14d after last play, skip keep-tagged items.
    Movies:  unmonitor in Radarr + delete file.
    Episodes: delete file + unmonitor in Sonarr. Series with keep tag are fully exempt.
    Rewatching resets the 14d clock via Jellyfin LastPlayedDate.
    """
    import argparse
    import logging
    import os
    import sys
    from datetime import datetime, timezone, timedelta
    from pathlib import Path

    import requests

    JELLYFIN_URL = "http://localhost:8096"
    JELLYFIN_USER_ID = "db57106d69264910bbc21a45dff572db"  # find via Jellyfin dashboard → Users → (click user) → check URL for UUID
    RADARR_URL = "http://localhost:7878"
    SONARR_URL = "http://localhost:8989"
    WATCHED_DAYS = 14
    KEEP_TAG_ID = 1
    CRED_DIR = Path(os.environ["CREDENTIALS_DIRECTORY"])

    log = logging.getLogger("media-churn")


    def jf_get(path, api_key, **params):
        r = requests.get(
            f"{JELLYFIN_URL}/{path}",
            headers={"X-Emby-Token": api_key},
            params=params,
            timeout=30,
        )
        r.raise_for_status()
        return r.json()


    def radarr(method, path, api_key, data=None, **params):
        params["apikey"] = api_key
        r = getattr(requests, method)(
            f"{RADARR_URL}/api/v3/{path}", params=params, json=data, timeout=30
        )
        r.raise_for_status()
        return r.json() if r.content else None


    def sonarr(method, path, api_key, data=None, **params):
        params["apikey"] = api_key
        r = getattr(requests, method)(
            f"{SONARR_URL}/api/v3/{path}", params=params, json=data, timeout=30
        )
        r.raise_for_status()
        return r.json() if r.content else None


    def parse_date(s):
        return datetime.fromisoformat(s.replace("Z", "+00:00"))


    def process_movies(jf_key, radarr_key, cutoff, dry_run):
        items = jf_get(
            f"Users/{JELLYFIN_USER_ID}/Items",
            jf_key,
            IsPlayed="true",
            IncludeItemTypes="Movie",
            Recursive="true",
            Fields="ProviderIds,UserData",
            Limit=1000,
        ).get("Items", [])

        eligible_tmdb = {}
        for item in items:
            ud = item.get("UserData", {})
            lpd = ud.get("LastPlayedDate")
            if not lpd or not ud.get("Played"):
                continue
            if parse_date(lpd) < cutoff:
                tmdb = item.get("ProviderIds", {}).get("Tmdb")
                if tmdb:
                    eligible_tmdb[int(tmdb)] = item["Name"]

        if not eligible_tmdb:
            log.info("movies: nothing past threshold")
            return

        radarr_movies = radarr("get", "movie", radarr_key)
        by_tmdb = {m["tmdbId"]: m for m in radarr_movies if m.get("tmdbId")}

        for tmdb_id, name in eligible_tmdb.items():
            movie = by_tmdb.get(tmdb_id)
            if not movie:
                log.warning(f"movies: '{name}' not in Radarr (tmdbId={tmdb_id}), skipping")
                continue
            if KEEP_TAG_ID in movie.get("tags", []):
                log.info(f"movies: '{name}' has keep tag, skipping")
                continue
            if not movie.get("hasFile"):
                log.info(f"movies: '{name}' has no file, skipping")
                continue

            prefix = "[DRY RUN] " if dry_run else ""
            log.info(f"movies: {prefix}deleting '{name}'")
            if not dry_run:
                movie_id = movie["id"]
                file_id = movie["movieFile"]["id"]
                movie["monitored"] = False
                radarr("put", f"movie/{movie_id}", radarr_key, data=movie)
                radarr("delete", f"moviefile/{file_id}", radarr_key)
                log.info(f"movies: deleted '{name}'")


    def process_episodes(jf_key, sonarr_key, cutoff, dry_run):
        items = jf_get(
            f"Users/{JELLYFIN_USER_ID}/Items",
            jf_key,
            IsPlayed="true",
            IncludeItemTypes="Episode",
            Recursive="true",
            Fields="Path,UserData",
            Limit=10000,
        ).get("Items", [])

        # path -> True if watched past cutoff
        eligible_paths = set()
        for item in items:
            ud = item.get("UserData", {})
            lpd = ud.get("LastPlayedDate")
            if not lpd or not ud.get("Played") or not item.get("Path"):
                continue
            if parse_date(lpd) < cutoff:
                eligible_paths.add(item["Path"])

        if not eligible_paths:
            log.info("episodes: nothing past threshold")
            return

        series_list = sonarr("get", "series", sonarr_key)
        keep_series = {s["id"] for s in series_list if KEEP_TAG_ID in s.get("tags", [])}

        for series in series_list:
            sid = series["id"]
            if sid in keep_series:
                log.info(f"episodes: series '{series['title']}' has keep tag, skipping")
                continue

            efiles = sonarr("get", "episodefile", sonarr_key, seriesId=sid)
            to_delete = [ef for ef in efiles if ef["path"] in eligible_paths]
            if not to_delete:
                continue

            # map episodeFileId -> [episode ids] for unmonitoring
            all_eps = sonarr("get", "episode", sonarr_key, seriesId=sid)
            file_to_ep_ids: dict[int, list[int]] = {}
            for ep in all_eps:
                fid = ep.get("episodeFileId")
                if fid:
                    file_to_ep_ids.setdefault(fid, []).append(ep["id"])

            for ef in to_delete:
                prefix = "[DRY RUN] " if dry_run else ""
                log.info(f"episodes: {prefix}deleting {ef['path']!r}")
                if not dry_run:
                    sonarr("delete", f"episodefile/{ef['id']}", sonarr_key)
                    ep_ids = file_to_ep_ids.get(ef["id"], [])
                    if ep_ids:
                        sonarr(
                            "put",
                            "episode/monitor",
                            sonarr_key,
                            data={"episodeIds": ep_ids, "monitored": False},
                        )
                    log.info(f"episodes: deleted file {ef['id']}, unmonitored {ep_ids}")


    def main():
        parser = argparse.ArgumentParser()
        parser.add_argument("--dry-run", action="store_true")
        args = parser.parse_args()

        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(name)s %(levelname)s %(message)s",
            stream=sys.stdout,
        )

        jf_key = (CRED_DIR / "jellyfin-api-key").read_text().strip()
        radarr_key = (CRED_DIR / "radarr-api-key").read_text().strip()
        sonarr_key = (CRED_DIR / "sonarr-api-key").read_text().strip()

        cutoff = datetime.now(timezone.utc) - timedelta(days=WATCHED_DAYS)
        log.info(f"cutoff: {cutoff.isoformat()} ({'dry run' if args.dry_run else 'live'})")

        process_movies(jf_key, radarr_key, cutoff, args.dry_run)
        process_episodes(jf_key, sonarr_key, cutoff, args.dry_run)


    if __name__ == "__main__":
        main()
  '';

  svcBase = args: {
    description = "Delete watched media past 14d threshold, skip keep-tagged";
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      ExecStart = "${python}/bin/python3 ${churnScript} ${args}";
      LoadCredential = [
        "jellyfin-api-key:${config.age.secrets.jellyfin-api-key.path}"
        "radarr-api-key:${config.age.secrets.radarr-api-key.path}"
        "sonarr-api-key:${config.age.secrets.sonarr-api-key.path}"
      ];
      PrivateNetwork = false;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
    };
  };
in
{
  age.secrets.jellyfin-api-key = {
    file = ../../secrets/jellyfin-api-key.age;
    mode = "0400";
  };

  systemd.services.media-churn = svcBase "";
  # test with: systemctl start media-churn-dry-run; journalctl -u media-churn-dry-run -e
  systemd.services.media-churn-dry-run = svcBase "--dry-run";

  systemd.timers.media-churn = {
    description = "Daily media churn at 3am";
    wantedBy = [ "timers.target" ];
    partOf = [ "media-churn.service" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
