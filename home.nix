{
  lib,
  pkgs,
  config,
  osConfig,
  inputs,
  ...
}: let
  username = osConfig.mySystem.user.name;
  homeDirectory = "/home/${username}";
in {
  imports = [
    ./modules/claude-code-enhanced
  ];

  # Enable Claude Code enhanced features
  programs.claude-code-enhanced.enable = true;

  # Override Fish shell colors for better visibility
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Fix parameter color (was 16081f - too dark)
      set -g fish_color_param b392f0  # base05 light purple
      # Optional: improve autosuggestion visibility
      set -g fish_color_autosuggestion 2f143f  # base03 medium purple

      # Improve syntax highlighting visibility
      set -g fish_color_command 66ccff  # base0C cyan - commands
      set -g fish_color_operator ffaa55  # base09 orange - operators like ; & |
      set -g fish_color_end ffaa55  # base09 orange - command terminators
      set -g fish_color_quote aaffaa  # base0B green - strings
      set -g fish_color_error ff6666  # base08 red - errors
      set -g fish_color_normal b392f0  # base05 light purple - normal text
      set -g fish_color_redirection 9999ff  # base0D blue - redirections
      set -g fish_color_option c7aaff  # base06 lighter purple - options/flags
    '';
  };

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  # Basic home packages (always included)
  home.packages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
    inputs.nh.packages.${pkgs.system}.default
    alejandra
    alarm-clock-applet
    btop
    cliphist
    dunst
    fastfetch
    fzf
    gh
    gparted
    grim
    hyprls
    hyprshot
    jq
    kitty
    nil
    nodejs
    pamixer
    python3
    rofi
    rustc
    slurp
    starship
    swww
    tldr
    ueberzugpp
    uv
    wl-clipboard
    wl-clip-persist
    wlogout
    wlsunset
  ];

  home.sessionVariables = {
    EDITOR = "zed";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "zed";
    XDG_TERMINAL_EDITOR = "kitty";
    # Ensure ~/.local/share is in XDG_DATA_DIRS so rofi finds our custom desktop files
    XDG_DATA_DIRS = "$HOME/.local/share:$XDG_DATA_DIRS";
  };

  # XDG MIME type associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Directories and file managers
      "inode/directory" = ["yazi.desktop" "thunar.desktop"];
      "inode/blockdevice" = ["thunar.desktop"];

      # Images - qView
      "image/bmp" = ["com.interversehq.qView.desktop"];
      "image/gif" = ["com.interversehq.qView.desktop"];
      "image/jpeg" = ["com.interversehq.qView.desktop"];
      "image/jpg" = ["com.interversehq.qView.desktop"];
      "image/png" = ["com.interversehq.qView.desktop"];
      "image/svg+xml" = ["com.interversehq.qView.desktop"];
      "image/tiff" = ["com.interversehq.qView.desktop"];
      "image/webp" = ["com.interversehq.qView.desktop"];

      # Videos - VLC
      "video/mp4" = ["vlc.desktop"];
      "video/mpeg" = ["vlc.desktop"];
      "video/quicktime" = ["vlc.desktop"];
      "video/webm" = ["vlc.desktop"];
      "video/x-matroska" = ["vlc.desktop"];
      "video/x-msvideo" = ["vlc.desktop"];

      # Audio - VLC
      "audio/aac" = ["vlc.desktop"];
      "audio/flac" = ["vlc.desktop"];
      "audio/mp3" = ["vlc.desktop"];
      "audio/mpeg" = ["vlc.desktop"];
      "audio/ogg" = ["vlc.desktop"];
      "audio/wav" = ["vlc.desktop"];
      "audio/webm" = ["vlc.desktop"];
      "audio/x-opus+ogg" = ["vlc.desktop"];
      "audio/x-vorbis+ogg" = ["vlc.desktop"];

      # Documents
      "application/pdf" = ["org.pwmt.zathura-pdf-mupdf.desktop"];

      # Text and code files
      "text/plain" = ["dev.zed.Zed.desktop"];
      "text/markdown" = ["dev.zed.Zed.desktop"];
      "text/x-csrc" = ["dev.zed.Zed.desktop"];
      "text/x-python" = ["dev.zed.Zed.desktop"];
      "application/x-shellscript" = ["dev.zed.Zed.desktop"];

      # Archives - File Roller
      "application/zip" = ["org.gnome.FileRoller.desktop"];
      "application/x-7z-compressed" = ["org.gnome.FileRoller.desktop"];
      "application/x-rar" = ["org.gnome.FileRoller.desktop"];
      "application/x-tar" = ["org.gnome.FileRoller.desktop"];
      "application/gzip" = ["org.gnome.FileRoller.desktop"];

      # Web - Helium
      "text/html" = ["helium.desktop"];
      "x-scheme-handler/http" = ["helium.desktop"];
      "x-scheme-handler/https" = ["helium.desktop"];

      # Terminal
      "application/x-terminal-emulator" = ["kitty.desktop"];
      "x-scheme-handler/terminal" = ["kitty.desktop"];

      # Torrents - Transmission
      "x-scheme-handler/magnet" = ["transmission-gtk.desktop"];
      "application/x-bittorrent" = ["transmission-gtk.desktop"];

      # Discord - Vesktop
      "x-scheme-handler/discord" = ["vesktop.desktop"];
    };
  };

  programs.home-manager.enable = true;

  # Claude Code project directory (conditional)
  home.file."claude-projects/.keep" = lib.mkIf osConfig.mySystem.features.claudeCode {
    text = "";
  };
}
