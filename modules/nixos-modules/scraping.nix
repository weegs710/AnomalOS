{
  flake.nixosModules.scraping = {
    config,
    lib,
    pkgs,
    ...
  }: let
      downloadVideo = pkgs.writeShellScriptBin "download-video" ''
        #!/usr/bin/env bash

        set -euo pipefail

        # Colors for output
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        YELLOW='\033[1;33m'
        NC='\033[0m' # No Color

        # Check if URL provided
        if [[ ''$# -eq 0 ]]; then
            echo -e "''${RED}Error: Please provide a YouTube video URL or playlist URL''${NC}"
            echo "Usage: scrapev <url>"
            echo "Example: scrapev 'https://www.youtube.com/watch?v=VIDEO_ID'"
            echo "Example: scrapev 'https://www.youtube.com/playlist?list=PLAYLIST_ID'"
            exit 1
        fi

        VIDEO_URL="''$1"
        VIDEO_DIR="''$HOME/Videos/yt-dlp"

        # Create output directory if it doesn't exist
        mkdir -p "''$VIDEO_DIR"
        cd "''$VIDEO_DIR"

        echo -e "''${BLUE}Downloading video(s)...''${NC}"
        echo -e "''${YELLOW}Format: 1080p H.264 video + AAC audio (MP4)''${NC}"

        # Download video with H.264 codec for maximum compatibility
        # Format 299: 1080p60 H.264, 140-12: AAC audio English
        # Falls back to best available if 299 not available
        ${pkgs.yt-dlp}/bin/yt-dlp \
          -f "299+140-12/bestvideo[height<=1080][vcodec^=avc]+bestaudio[acodec^=mp4a]/best[height<=1080]" \
          --merge-output-format mp4 \
          --ignore-errors \
          -o "%(title)s.%(ext)s" \
          "''$VIDEO_URL"

        echo -e "''${GREEN}Download complete!''${NC}"
        echo -e "''${GREEN}Videos saved to: ''$VIDEO_DIR''${NC}"
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

        def save-config [music_dir: string] {
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

        def get-playlist-name [url: string]: nothing -> string {
            let result = ^yt-dlp --flat-playlist --print "%(playlist_title)s" $url | complete
            if $result.exit_code == 0 and ($result.stdout | str trim | is-not-empty) {
                $result.stdout | str trim | lines | first
            } else {
                print $"  (ansi yellow)Could not automatically fetch playlist name.(ansi reset)"
                let name = input "  [?] Please enter a name for this playlist: " | str trim
                if ($name | is-empty) {
                    print $"  (ansi red)Error: Playlist name cannot be empty(ansi reset)"
                    exit 1
                }
                $name
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
            let title = if ($metadata | is-empty) {
                "Unknown Title"
            } else {
                $metadata.title? | default "Unknown Title" | into string
            }

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
                    if ($line | str contains "[download] Downloading item") {
                        print $"  ($line)"
                    } else if ($line | str contains "ERROR:") {
                        print $"  (ansi red)($line)(ansi reset)"
                    }
                } | ignore
            }
            $env.LAST_EXIT_CODE
        }

        def download-album [url: string, metadata: record, music_dir: string, verbose: bool, log_file: string] {
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

            let ppargs = $"ffmpeg:-metadata artist=($metadata.artist | shell-quote) -metadata album=($metadata.album | shell-quote) -loglevel error"
            let output_template = [$album_dir, "%(title)s - %(artist)s - %(album)s.%(ext)s"] | path join

            let dl_args = [
                "-x" "--audio-format" "mp3"
                "--add-metadata" "--embed-thumbnail"
                "--metadata" $"artist=($metadata.artist)"
                "--metadata" $"album=($metadata.album)"
                "--parse-metadata" "playlist_index:%(track_number)s"
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

        def print-intro [music_dir: string] {
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

        def run-download [url: string, verbose: bool, do_log: bool, music_dir: string] {
            get-playlist-name $url | ignore  # verify URL is accessible

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

            if $url != null {
                run-download $url $verbose (not $no_log) $music_dir
            } else {
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
        }
      '';
    in {
      config = lib.mkIf config.mySystem.features.media {
        environment.systemPackages = with pkgs; [
          yt-dlp
          downloadVideo
        ];

        environment.shellAliases = {
          scrapev = "download-video";
        };

        hjem.users.${config.mySystem.user.name}.xdg.config.files."snag/snag.nu".text = snagScript;
      };
    };
}
