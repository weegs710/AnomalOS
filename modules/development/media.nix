{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  downloadPlaylist = pkgs.writeShellScriptBin "download-playlist" ''
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
        echo -e "''${RED}Error: Please provide a YouTube/YouTube Music playlist URL''${NC}"
        echo "Usage: scrapem <url>"
        echo "Example: scrapem 'https://music.youtube.com/playlist?list=PLAYLIST_ID'"
        exit 1
    fi

    PLAYLIST_URL="''$1"
    MUSIC_DIR="''$HOME/Music"

    echo -e "''${BLUE}Fetching playlist information...''${NC}"

    # Try to extract playlist title with a timeout
    PLAYLIST_NAME=$(timeout 15 ${pkgs.yt-dlp}/bin/yt-dlp --flat-playlist --print "%(playlist_title)s" "''$PLAYLIST_URL" 2>/dev/null | head -1 || echo "")

    # Fallback: if extraction fails or times out, ask user
    if [[ -z "''$PLAYLIST_NAME" ]]; then
        echo -e "''${YELLOW}Could not automatically fetch playlist name.''${NC}"
        read -p "Please enter a name for this playlist: " PLAYLIST_NAME

        if [[ -z "''$PLAYLIST_NAME" ]]; then
            echo -e "''${RED}Error: Playlist name cannot be empty''${NC}"
            exit 1
        fi
    fi

    echo -e "''${GREEN}Playlist name: ''$PLAYLIST_NAME''${NC}"

    # Create directory
    if [[ -d "''$MUSIC_DIR/''$PLAYLIST_NAME" ]]; then
        echo -e "''${RED}Directory already exists: ''$MUSIC_DIR/''$PLAYLIST_NAME''${NC}"
        read -p "Overwrite? (y/n) " -n 1 -r
        echo
        if [[ ! "''$REPLY" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        mkdir -p "''$MUSIC_DIR/''$PLAYLIST_NAME"
    fi

    cd "''$MUSIC_DIR/''$PLAYLIST_NAME"

    echo -e "''${BLUE}Downloading playlist...''${NC}"

    # Download all tracks as MP3s, stripping video IDs from filenames
    ${pkgs.yt-dlp}/bin/yt-dlp -x --audio-format mp3 --ignore-errors -o "%(title)s.%(ext)s" "''$PLAYLIST_URL"

    echo -e "''${GREEN}Download complete!''${NC}"
    echo -e "''${BLUE}Creating MPD-compatible playlist file...''${NC}"

    # Ensure playlists directory exists
    mkdir -p "''$MUSIC_DIR/playlists"

    # Create MPD playlist with paths relative to MUSIC_DIR
    {
        echo "#EXTM3U"
        ls -1tr *.mp3 2>/dev/null | while read -r file; do
            title="''${file%.mp3}"
            echo "#EXTINF:-1,''$title"
            echo "''$PLAYLIST_NAME/''$file"
        done
    } > "''$MUSIC_DIR/playlists/''${PLAYLIST_NAME}.m3u"

    echo -e "''${GREEN}Playlist file created: ''$MUSIC_DIR/playlists/''${PLAYLIST_NAME}.m3u''${NC}"
    echo -e "''${GREEN}Music files saved to: ''$MUSIC_DIR/''$PLAYLIST_NAME/''${NC}"
    echo -e "''${GREEN}All done!''${NC}"
  '';

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
in {
  options.mySystem.features.media = mkEnableOption "Media tools (YouTube playlist downloader)";

  config = mkIf config.mySystem.features.media {
    environment.systemPackages = with pkgs; [
      yt-dlp
      downloadPlaylist
      downloadVideo
    ];

    environment.shellAliases = {
      scrapem = "download-playlist";
      scrapev = "download-video";
      snag = "cd ~/Documents/test-zone/ && ./snag.py";
    };
  };
}
