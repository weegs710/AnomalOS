{
  lib,
  pkgs,
  config,
  osConfig,
  inputs,
  ...
}:
let
  username = osConfig.mySystem.user.name;
  homeDirectory = "/home/${username}";
in
{
  imports = [
    ./modules/claude-code-enhanced
  ];

  programs.claude-code-enhanced.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_color_param b392f0  # base05 light purple
      set -g fish_color_autosuggestion 2f143f  # base03 medium purple
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

  home.packages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
    inputs.nh.packages.${pkgs.system}.default
    alejandra
    alarm-clock-applet
    btop
    cliphist
    fastfetch
    fzf
    gh
    gparted
    grim
    hyprls
    hyprshot
    jan
    jq
    nodejs
    pamixer
    python3
    rofi
    rustc
    slurp
    starship
    swww
    xdg-desktop-portal-gtk
    xfce.thunar
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

  # Thunar installed for GTK portal FileChooser dependency (yazi doesn't provide one)
  xdg.desktopEntries = {
    "thunar" = {
      name = "Thunar";
      noDisplay = true;
    };
    "thunar-bulk-rename" = {
      name = "Thunar Bulk Rename";
      noDisplay = true;
    };
    "thunar-settings" = {
      name = "Thunar Settings";
      noDisplay = true;
    };
    "thunar-volman-settings" = {
      name = "Thunar Volume Manager Settings";
      noDisplay = true;
    };
    "qt5ct" = {
      name = "Qt5 Settings";
      noDisplay = true;
    };
    "qt6ct" = {
      name = "Qt6 Settings";
      noDisplay = true;
    };
    "kvantummanager" = {
      name = "Kvantum Manager";
      noDisplay = true;
    };
    "org.pulseaudio.pavucontrol" = {
      name = "PulseAudio Volume Control";
      noDisplay = true;
    };
    "com.interversehq.qView" = {
      name = "qView";
      noDisplay = true;
    };
  };

  # XDG MIME type associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Directories and file managers
      "inode/directory" = [
        "yazi.desktop"
        "thunar.desktop"
      ];
      "inode/blockdevice" = [ "thunar.desktop" ];

      # Images - qView
      "image/bmp" = [ "com.interversehq.qView.desktop" ];
      "image/gif" = [ "com.interversehq.qView.desktop" ];
      "image/jpeg" = [ "com.interversehq.qView.desktop" ];
      "image/jpg" = [ "com.interversehq.qView.desktop" ];
      "image/png" = [ "com.interversehq.qView.desktop" ];
      "image/svg+xml" = [ "com.interversehq.qView.desktop" ];
      "image/tiff" = [ "com.interversehq.qView.desktop" ];
      "image/webp" = [ "com.interversehq.qView.desktop" ];

      # Videos - VLC
      "video/mp4" = [ "vlc.desktop" ];
      "video/mpeg" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/x-msvideo" = [ "vlc.desktop" ];

      # Audio - VLC
      "audio/aac" = [ "vlc.desktop" ];
      "audio/flac" = [ "vlc.desktop" ];
      "audio/mp3" = [ "vlc.desktop" ];
      "audio/mpeg" = [ "vlc.desktop" ];
      "audio/ogg" = [ "vlc.desktop" ];
      "audio/wav" = [ "vlc.desktop" ];
      "audio/webm" = [ "vlc.desktop" ];
      "audio/x-opus+ogg" = [ "vlc.desktop" ];
      "audio/x-vorbis+ogg" = [ "vlc.desktop" ];

      # Documents
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];

      # Text and code files
      "text/plain" = [ "dev.zed.Zed.desktop" ];
      "text/markdown" = [ "dev.zed.Zed.desktop" ];
      "text/x-csrc" = [ "dev.zed.Zed.desktop" ];
      "text/x-python" = [ "dev.zed.Zed.desktop" ];
      "application/x-shellscript" = [ "dev.zed.Zed.desktop" ];

      # Archives - File Roller
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];

      # Web - Helium
      "text/html" = [ "helium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];

      # Terminal
      "application/x-terminal-emulator" = [ "kitty.desktop" ];
      "x-scheme-handler/terminal" = [ "kitty.desktop" ];

      # Torrents - Transmission
      "x-scheme-handler/magnet" = [ "transmission-gtk.desktop" ];
      "application/x-bittorrent" = [ "transmission-gtk.desktop" ];

      # Discord - Vesktop
      "x-scheme-handler/discord" = [ "vesktop.desktop" ];
    };
  };

  programs.home-manager.enable = true;

  # Claude Code project directory (conditional)
  home.file."claude-projects/.keep" = lib.mkIf osConfig.mySystem.features.claudeCode {
    text = "";
  };
}
