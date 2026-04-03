{
  flake.nixosModules.scraping = {
    config,
    lib,
    pkgs,
    ...
  }: let
    yoinkScript = ''
      #!/usr/bin/env nu

      const CONFIG_FILE = ("~/.config/yoink/config.json" | path expand)
      const LOG_DIR = ("~/.config/yoink/logs" | path expand)
      const DEFAULT_VIDEO_DIR = ("~/Videos/yt-dlp" | path expand)

      def write-log [log_file: string]: string -> nothing {
          if ($log_file | is-empty) { return }
          let plain = $in | ansi strip | str trim
          if ($plain | is-not-empty) {
              $"($plain)\n" | save --append $log_file
          }
      }

      def load-config []: nothing -> string {
          if ($CONFIG_FILE | path exists) {
              try {
                  (open $CONFIG_FILE).video_dir? | default $DEFAULT_VIDEO_DIR
              } catch {
                  $DEFAULT_VIDEO_DIR
              }
          } else {
              $DEFAULT_VIDEO_DIR
          }
      }

      def save-config [video_dir: string]: nothing -> nothing {
          mkdir ($CONFIG_FILE | path dirname)
          {video_dir: $video_dir} | save --force $CONFIG_FILE
          print $"(ansi green)Configuration saved.(ansi reset)"
      }

      def setup-log-file [title: string]: nothing -> string {
          mkdir $LOG_DIR
          let timestamp = date now | format date "%m-%d-%y - %H%M"
          let safe_title = $title | str replace --regex --all '[<>:"/\\|?*]' ""
          let log_path = [$LOG_DIR, $"($timestamp) - ($safe_title).log"] | path join
          "" | save $log_path
          $log_path
      }

      def verify-url [url: string]: nothing -> nothing {
          let result = ^yt-dlp --flat-playlist --print '%(title)s' --no-warnings $url | complete
          if $result.exit_code != 0 or ($result.stdout | str trim | is-empty) {
              error make {msg: $"Could not reach or parse URL: ($url)"}
          }
      }

      def extract-info [url: string]: nothing -> record {
          let result = ^yt-dlp --flat-playlist --print '%(title)s' --no-warnings $url | complete
          if $result.exit_code != 0 {
              return {title: "download", count: 1, playlist_title: ""}
          }
          let titles = $result.stdout | str trim | lines | where { not ($in | is-empty) }
          let count = $titles | length
          let title = $titles | first | default "download"

          # for playlists, grab the playlist title separately for the output directory name
          let playlist_title = if $count > 1 {
              let pt = ^yt-dlp --flat-playlist --playlist-items 1 --print '%(playlist_title)s' --no-warnings $url | complete
              if $pt.exit_code == 0 { $pt.stdout | str trim } else { "" }
          } else {
              ""
          }

          {title: $title, count: $count, playlist_title: $playlist_title}
      }

      def run-ytdlp-stream [args: list<string>, verbose: bool, log_file: string]: nothing -> int {
          if $verbose {
              ^yt-dlp ...$args o+e>| lines | each { print $in } | ignore
          } else {
              ^yt-dlp ...$args o+e>| lines | each { |line|
                  $line | write-log $log_file
                  match $line {
                      _ if ($line | str contains "[download]") and ($line | str contains "%") => { print $"  ($line)" }
                      _ if ($line | str contains "[download] Downloading item") => { print $"  ($line)" }
                      _ if ($line | str contains "[Merger]") => { print $"  (ansi blue)Merging streams...(ansi reset)" }
                      _ if ($line | str contains "ERROR:") => { print $"  (ansi red)($line)(ansi reset)" }
                      _ => {}
                  }
              } | ignore
          }
          $env.LAST_EXIT_CODE
      }

      def build-args [url: string, mode: string, output_template: string]: nothing -> list<string> {
          let format = if $mode == "lite" {
              'bestvideo[height<=1080][height>=720]+bestaudio/bestvideo[height<=1080]+bestaudio/best[height<=1080]'
          } else {
              'bestvideo[vcodec^=avc]+bestaudio[acodec^=mp4a]/best'
          }
          let container = if $mode == "lite" { "mp4" } else { "mkv" }

          [
              "-f" $format
              "--merge-output-format" $container
              "--ignore-errors"
              "--force-overwrites"
              "--no-write-playlist-metafiles"
              "--write-description"
              "--write-info-json"
              "--write-auto-subs"
              "--sub-langs" "en.*"
              "--sub-format" "srt"
              "--embed-metadata"
              "-o" $output_template
              $url
          ]
      }

      def print-intro [video_dir: string, mode: string]: nothing -> nothing {
          let line = 1..8 | each { "=" } | str join ""
          let mode_label = if $mode == "lite" { "Lite (720-1080p, MP4)" } else { "Max (H.264, best res, MKV)" }
          print $"\n  (ansi blue)($line)(ansi reset)"
          print $"(ansi blue_bold)  Yoink!(ansi reset)"
          print $"  (ansi blue)($line)(ansi reset)"
          print "\n  YouTube Video Downloader"
          print $"  Mode:   (ansi cyan)($mode_label)(ansi reset)"
          print $"  Output: (ansi cyan)($video_dir)(ansi reset)"
          print $"  For detailed usage: (ansi green)yoink --help(ansi reset)"
      }

      def ask-bool [prompt: string]: nothing -> bool {
          input $"\n  (ansi attr_bold)[?](ansi reset) ($prompt) [y/N]: " | str trim | str downcase | str starts-with "y"
      }

      def run-download [url: string, mode: string, verbose: bool, do_log: bool, video_dir: string]: nothing -> nothing {
          verify-url $url
          let info = extract-info $url

          if $info.count > 1 {
              print $"\n  (ansi yellow)Playlist detected: ($info.count) videos(ansi reset)"
              if not (ask-bool $"Download all ($info.count) videos?") {
                  print $"  (ansi yellow)Cancelled.(ansi reset)"
                  return
              }
          }

          mkdir $video_dir

          # single video: Title/Title.ext
          # playlist: Playlist Name/01 - Title/01 - Title.ext
          let output_template = if $info.count > 1 {
              let playlist_dir = if ($info.playlist_title | is-not-empty) {
                  $info.playlist_title
              } else {
                  "Playlist"
              }
              [$video_dir, $playlist_dir, '%(playlist_index)s - %(title)s', '%(playlist_index)s - %(title)s.%(ext)s'] | path join
          } else {
              [$video_dir, '%(title)s', '%(title)s.%(ext)s'] | path join
          }

          let log_file = if $do_log { setup-log-file $info.title } else { "" }

          let mode_label = if $mode == "lite" { "720-1080p H.264/AAC, MP4" } else { "H.264 max res + AAC, MKV" }
          let sep = 1..48 | each { "=" } | str join ""
          print $"\n  (ansi blue)($sep)(ansi reset)"
          if $info.count > 1 {
              print $"  (ansi blue_underline)(ansi attr_bold)Playlist(ansi reset)(ansi blue) : (ansi cyan)($info.playlist_title)(ansi reset)"
              print $"  (ansi blue_underline)(ansi attr_bold)Videos(ansi reset)(ansi blue)   : (ansi cyan)($info.count)(ansi reset)"
          } else {
              print $"  (ansi blue_underline)(ansi attr_bold)Title(ansi reset)(ansi blue)    : (ansi cyan)($info.title)(ansi reset)"
          }
          print $"  (ansi blue_underline)(ansi attr_bold)Mode(ansi reset)(ansi blue)     : (ansi cyan)($mode_label)(ansi reset)"
          print $"  (ansi blue_underline)(ansi attr_bold)Output(ansi reset)(ansi blue)   : (ansi cyan)($video_dir)(ansi reset)"
          print $"  (ansi blue)($sep)(ansi reset)"

          let args = build-args $url $mode $output_template
          $"CMD: yt-dlp ($args | str join ' ')" | write-log $log_file

          let exit_code = run-ytdlp-stream $args $verbose $log_file

          if $exit_code == 0 {
              let search_dir = if $info.count > 1 {
                  let playlist_dir = if ($info.playlist_title | is-not-empty) { $info.playlist_title } else { "Playlist" }
                  [$video_dir, $playlist_dir] | path join
              } else {
                  $video_dir
              }
              glob $"($search_dir)/**/*.info.json" | each { |json_file|
                  let url = try { (open $json_file).webpage_url? | default "" } catch { "" }
                  if ($url | str starts-with "http") {
                      let html_file = $json_file | str replace --all ".info.json" ".source.html"
                      $"<!DOCTYPE html><html><head><meta http-equiv=\"refresh\" content=\"0;url=($url)\"></head></html>" | save --force $html_file
                  }
              } | ignore

              print $"\n  (ansi green)Done!(ansi reset)"
              print $"  Saved to:  ($video_dir)"
              print $"  Source links written to .source.html alongside each video"
              if ($log_file | is-not-empty) {
                  print $"  Log: ($log_file)"
              }
          } else {
              print $"\n  (ansi red)yt-dlp exited with code ($exit_code)(ansi reset)"
              if ($log_file | is-not-empty) {
                  print $"  (ansi yellow)Check log: ($log_file)(ansi reset)"
              }
              exit $exit_code
          }
      }

      # Yoink! - YouTube Video Downloader
      def main [
          url?: string       # YouTube URL (video or playlist)
          --lite (-l)        # 720-1080p, smaller filesize (default: max res H.264)
          --verbose (-v)     # Enable verbose yt-dlp output
          --no-log           # Disable logging to ~/.config/yoink/logs/
          --set-dir: string  # Set a new persistent default output directory
      ] {
          let video_dir = load-config
          let mode = if $lite { "lite" } else { "max" }

          if $set_dir != null {
              let new_path = $set_dir | path expand
              mkdir $new_path
              save-config $new_path
              print $"(ansi green)Default output updated to: ($new_path)(ansi reset)"
              return
          }

          match $url {
              null => {
                  print-intro $video_dir $mode

                  mut entered_url = ""
                  loop {
                      let u = input "\n  [?] Enter Video/Playlist URL: " | str trim
                      if ($u | is-not-empty) { $entered_url = $u; break }
                      print $"      (ansi red)URL cannot be empty.(ansi reset)"
                  }

                  let be_verbose = ask-bool "Enable verbose output?"
                  run-download $entered_url $mode $be_verbose true $video_dir
              }
              _ => { run-download $url $mode $verbose (not $no_log) $video_dir }
          }
      }
    '';
    snagScript = ''
      #!/usr/bin/env nu

      const CONFIG_FILE = ("~/.config/snag/config.json" | path expand)
      const LOG_DIR = ("~/.config/snag/logs" | path expand)
      const DEFAULT_MUSIC_DIR = ("~/Music" | path expand)

      def title-case []: string -> string {
          split row " "
          | each { if ($in | is-empty) { $in } else { str capitalize } }
          | str join " "
      }

      def shell-quote []: string -> string {
          let s = $in | str replace --all "'" "'\\'''"
          $"'($s)'"
      }

      def write-log [log_file: string]: string -> nothing {
          if ($log_file | is-empty) { return }
          let plain = $in | ansi strip | str trim
          if ($plain | is-not-empty) {
              $"($plain)\n" | save --append $log_file
          }
      }

      def load-config []: nothing -> string {
          if ($CONFIG_FILE | path exists) {
              try {
                  (open $CONFIG_FILE).music_dir? | default $DEFAULT_MUSIC_DIR
              } catch {
                  $DEFAULT_MUSIC_DIR
              }
          } else {
              $DEFAULT_MUSIC_DIR
          }
      }

      def save-config [music_dir: string]: nothing -> nothing {
          mkdir ($CONFIG_FILE | path dirname)
          {music_dir: $music_dir} | save --force $CONFIG_FILE
          print $"(ansi green)Configuration saved.(ansi reset)"
      }

      def setup-log-file [album_name: string]: nothing -> string {
          mkdir $LOG_DIR
          let timestamp = date now | format date "%m-%d-%y - %H%M"
          let safe_album = $album_name | str replace --regex --all '[<>:"/\\|?*]' ""
          let log_path = [$LOG_DIR, $"($timestamp) - ($safe_album).log"] | path join
          "" | save $log_path
          $log_path
      }

      def verify-url [url: string]: nothing -> nothing {
          let result = ^yt-dlp --flat-playlist --print "%(playlist_title)s" $url | complete
          if $result.exit_code != 0 or ($result.stdout | str trim | is-empty) {
              error make {msg: $"Could not reach or parse URL: ($url)"}
          }
      }

      def extract-metadata [url: string]: nothing -> record {
          let result = ^yt-dlp --playlist-items 1 --dump-json --no-warnings $url | complete
          if $result.exit_code != 0 or ($result.stdout | str trim | is-empty) {
              return {}
          }
          try {
              let data = $result.stdout | str trim | lines | first | from json

              let artist_raw = (
                  $data.artist?
                  | default $data.uploader?
                  | default $data.channel?
                  | default "Unknown Artist"
              ) | into string

              let album = (
                  $data.album?
                  | default $data.playlist_title?
                  | default "Unknown Album"
              ) | into string

              let title = ($data.title? | default "Unknown Title") | into string
              let artist = $artist_raw | str replace --regex " - Topic$" "" | title-case
              let artist_folder = $artist | split row "," | first | str trim

              let track_number = try {
                  ($data.track_number? | default $data.playlist_index?) | into int
              } catch { null }

              {
                  title: $title
                  artist: $artist
                  artist_folder: $artist_folder
                  album: $album
                  track_number: $track_number
              }
          } catch {
              {}
          }
      }

      def ask-metadata-fallback [url: string, metadata: record]: nothing -> record {
          print $"  (ansi yellow)Could not extract complete metadata.(ansi reset)"
          print $"  (ansi blue)Please visit: ($url)(ansi reset)"

          let artist = input "  [?] Enter artist name: " | str trim
          let album = input "  [?] Enter album name: " | str trim
          let artist_folder = $artist | split row "," | first | str trim
          let title = $metadata.title? | default "Unknown Title" | into string

          {title: $title, artist: $artist, artist_folder: $artist_folder, album: $album, track_number: null}
      }

      def ask-collision-action [album_dir: string]: nothing -> string {
          print $"\n  (ansi yellow)Album directory already exists: ($album_dir)(ansi reset)"
          print "  [S]kip | [O]verwrite | [M]erge (add missing tracks)"

          mut result = ""
          loop {
              let choice = input $"  (ansi attr_bold)Your choice:(ansi reset) " | str trim | str downcase
              match $choice {
                  "s" => { $result = "skip";      break }
                  "o" => { $result = "overwrite"; break }
                  "m" => { $result = "merge";     break }
                  _   => { print $"  (ansi red)Invalid choice. Please enter S, O, or M.(ansi reset)" }
              }
          }
          $result
      }

      def run-ytdlp-stream [args: list<string>, verbose: bool, log_file: string]: nothing -> int {
          if $verbose {
              ^yt-dlp ...$args o+e>| lines | each { print $in } | ignore
          } else {
              ^yt-dlp ...$args o+e>| lines | each { |line|
                  $line | write-log $log_file
                  match $line {
                      _ if ($line | str contains "[download] Downloading item") => { print $"  ($line)" }
                      _ if ($line | str contains "ERROR:") => { print $"  (ansi red)($line)(ansi reset)" }
                      _ => {}
                  }
              } | ignore
          }
          $env.LAST_EXIT_CODE
      }

      def download-album [url: string, metadata: record, music_dir: string, verbose: bool, log_file: string]: nothing -> nothing {
          let album_dir = [$music_dir, $metadata.artist_folder, $metadata.album] | path join

          if ($album_dir | path exists) {
              match (ask-collision-action $album_dir) {
                  "skip" => {
                      print $"  (ansi yellow)Skipping download. Album already exists.(ansi reset)"
                      return
                  }
                  "overwrite" => {
                      print $"  (ansi yellow)Removing existing directory...(ansi reset)"
                      rm --recursive --force $album_dir
                  }
                  _ => {} # merge: fall through
              }
          }

          mkdir $album_dir
          print $"\n  (ansi blue)Downloading album...(ansi reset)"

          # album_artist is intentionally static — provides consistent grouping across all tracks
          let ppargs = $"ffmpeg:-metadata album_artist=($metadata.artist | shell-quote) -loglevel error"
          let output_template = [$album_dir, "%(title)s - %(artist)s - %(album)s.%(ext)s"] | path join

          let dl_args = [
              "-x" "--audio-format" "mp3"
              "--add-metadata" "--embed-thumbnail"
              # per-track: use each track's own album field, fall back to playlist title
              "--parse-metadata" "%(album,playlist_title)s:%(meta_album)s"
              # per-track: map playlist index to embedded track number
              "--parse-metadata" "%(playlist_index)s:%(meta_track)s"
              # strip YouTube auto-generated " - Topic" suffix from artist fields
              "--replace-in-metadata" "artist" " - Topic$" ""
              "--ignore-errors"
              "--js-runtimes" "node"
              "--remote-components" "ejs:github"
              "-o" $output_template
              "--postprocessor-args" $ppargs
              $url
          ]

          $"CMD: yt-dlp ($dl_args | str join ' ')" | write-log $log_file

          let returncode = run-ytdlp-stream $dl_args $verbose $log_file

          if $returncode != 0 {
              print $"\n  (ansi red)Download failed with exit code ($returncode)(ansi reset)"
              if ($log_file | is-not-empty) {
                  print $"  (ansi yellow)Check log: ($log_file)(ansi reset)"
              }
              exit 1
          }

          ^yt-dlp --skip-download --write-thumbnail --convert-thumbnails jpg --playlist-items 1 --js-runtimes node --remote-components ejs:github -o $"($album_dir)/thumbnail:cover" $url | ignore

          print $"\n  (ansi green)Success!(ansi reset)"
          print $"  Album saved to: ($album_dir)"
      }

      def print-intro [music_dir: string]: nothing -> nothing {
          let line = 1..8 | each { "=" } | str join ""
          print $"\n  (ansi blue)($line)(ansi reset)"
          print $"(ansi blue_bold)  Snag It?(ansi reset)"
          print $"  (ansi blue)($line)(ansi reset)"
          print "\n  Automated Album Downloader & Organizer"
          print $"  Library Location: (ansi cyan)($music_dir)(ansi reset)"
          print $"  For detailed usage: (ansi green)snag --help(ansi reset)"
      }

      def ask-bool [prompt: string]: nothing -> bool {
          input $"\n  (ansi attr_bold)[?](ansi reset) ($prompt) [y/N]: " | str trim | str downcase | str starts-with "y"
      }

      def run-download [url: string, verbose: bool, do_log: bool, music_dir: string]: nothing -> nothing {
          verify-url $url

          let metadata_raw = extract-metadata $url

          let needs_fallback = if ($metadata_raw | is-empty) {
              true
          } else {
              $metadata_raw.artist == "Unknown Artist" or $metadata_raw.album == "Unknown Album"
          }

          let metadata = if $needs_fallback {
              ask-metadata-fallback $url $metadata_raw
          } else {
              $metadata_raw
          }

          let log_file = if $do_log { setup-log-file $metadata.album } else { "" }

          let sep = 1..48 | each { "=" } | str join ""
          print $"\n  (ansi blue)($sep)(ansi reset)"
          print $"  (ansi blue_underline)(ansi attr_bold)Artist(ansi reset)(ansi blue) : (ansi cyan)($metadata.artist)(ansi reset)"
          print $"  (ansi blue_underline)(ansi attr_bold)Album(ansi reset)(ansi blue)  : (ansi cyan)($metadata.album)(ansi reset)"
          print $"  (ansi blue)($sep)(ansi reset)"

          download-album $url $metadata $music_dir $verbose $log_file
      }

      # Snag It? - Automated Album Downloader & Organizer
      def main [
          url?: string       # YouTube/YouTube Music playlist URL
          --verbose (-v)     # Enable verbose output
          --no-log           # Disable logging to ~/.config/snag/logs/
          --set-dir: string  # Set a new persistent default music library location
      ] {
          let music_dir = load-config

          if $set_dir != null {
              let new_path = $set_dir | path expand
              mkdir $new_path
              save-config $new_path
              print $"(ansi green)Default library location updated to: ($new_path)(ansi reset)"
              return
          }

          match $url {
              null => {
                  print-intro $music_dir

                  mut entered_url = ""
                  loop {
                      let u = input "\n  [?] Enter Album/Playlist URL: " | str trim
                      if ($u | is-not-empty) { $entered_url = $u; break }
                      print $"      (ansi red)URL cannot be empty.(ansi reset)"
                  }

                  let be_verbose = ask-bool "Enable verbose console output?"
                  run-download $entered_url $be_verbose true $music_dir
              }
              _ => { run-download $url $verbose (not $no_log) $music_dir }
          }
      }
    '';

    syncMusicScript = ''
      #!/usr/bin/env nu

      # Sync ~/Music to Android via ADB.
      # Dirs/files with exFAT-illegal chars (: ? |) are temporarily renamed before push
      # and restored after. Uses --sync to skip files already on device.

      def make-safe []: string -> string {
          str replace --all ':' '：'
          | str replace --all '?' '？'
          | str replace --all '|' '｜'
      }

      def make-unsafe []: string -> string {
          str replace --all '：' ':'
          | str replace --all '？' '?'
          | str replace --all '｜' '|'
      }

      def find-bad-dirs [music_dir: string]: nothing -> list<string> {
          glob $"($music_dir)/**/*"
          | where { ($in | path type) == "dir" }
          | where {
              let name = $in | path basename
              ($name | str contains ':') or ($name | str contains '?') or ($name | str contains '|')
          }
          | sort
      }

      def find-thumbnails [music_dir: string]: nothing -> list<string> {
          glob $"($music_dir)/**/thumbnail*cover.jpg"
          | where { ($in | path basename) == "thumbnail:cover.jpg" }
          | sort
      }

      def rename-dirs [dirs: list<string>]: nothing -> list<record<old: string, new: string>> {
          $dirs | each { |d|
              let new_path = ($d | path dirname) | path join ($d | path basename | make-safe)
              mv $d $new_path
              {old: $d, new: $new_path}
          }
      }

      def restore-dirs [renamed: list<record<old: string, new: string>>] {
          $renamed | reverse | each { |r|
              if ($r.new | path exists) { mv $r.new $r.old }
          } | ignore
      }

      # Returns the original thumbnail paths (with fullwidth dir names) for later restoration.
      # Must be called after rename-dirs so the paths are valid on disk.
      def hide-thumbnails [music_dir: string]: nothing -> list<string> {
          let thumbs = find-thumbnails $music_dir
          $thumbs | each { |t|
              mv $t ($t | path dirname | path join "thumbnail_cover.jpg")
          } | ignore
          $thumbs
      }

      def restore-thumbnails [original_paths: list<string>] {
          $original_paths | each { |orig|
              let hidden = $orig | path dirname | path join "thumbnail_cover.jpg"
              if ($hidden | path exists) { mv $hidden $orig }
          } | ignore
      }

      # Sync ~/Music to Android via ADB, skipping files already on device
      def main [--dry-run (-n)] {
          let music_dir = $env.HOME | path join "Music"
          let bad_dirs = find-bad-dirs $music_dir

          if $dry_run {
              let thumbs = find-thumbnails $music_dir
              print "=== DRY RUN ==="
              print $"\nDirectories to rename \(($bad_dirs | length) total\):"
              $bad_dirs | each { |d|
                  print $"  ($d | path basename)"
                  print $"  → ($d | path basename | make-safe)"
              } | ignore
              print $"\nThumbnails to hide \(($thumbs | length) total\)"
              print "\nNo changes made."
              return
          }

          print $"Renaming ($bad_dirs | length) dirs..."
          let renamed = rename-dirs $bad_dirs

          print "Hiding thumbnails..."
          let thumb_originals = hide-thumbnails $music_dir

          print "Syncing to device (skipping existing files)..."
          ^adb push --sync $"($music_dir)/." /sdcard/Music/
          let push_exit = $env.LAST_EXIT_CODE

          print "Restoring thumbnails..."
          restore-thumbnails $thumb_originals
          print "Restoring dirs..."
          restore-dirs $renamed

          if $push_exit == 0 {
              print "Sync complete."
          } else {
              print $"Sync failed \(exit code: ($push_exit)\) — local changes restored."
              exit $push_exit
          }
      }
    '';
  in {
    config = lib.mkIf config.mySystem.features.media {
      environment.systemPackages = with pkgs; [
        yt-dlp
      ];

      environment.shellAliases = {
        yoink = "nu ~/.config/yoink/yoink.nu";
        sync-music = "nu ~/.config/sync-music/sync-music.nu";
      };

      hjem.users.${config.mySystem.user.name}.xdg.config.files = {
        "snag/snag.nu".text = snagScript;
        "yoink/yoink.nu".text = yoinkScript;
        "sync-music/sync-music.nu".text = syncMusicScript;
      };
    };
  };
}
