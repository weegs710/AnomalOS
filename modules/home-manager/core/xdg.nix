{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  username = osConfig.mySystem.user.name;
  homeDirectory = "/home/${username}";

  axion-cursors = pkgs.oreo-cursors-plus.override {
    cursorsConf = ''
      axion-cyan = color: #21d6c9, label: #e8f6f5, shadow: #000000, shadow-opacity: 0.4, stroke: #5ec4bc, stroke-opacity: 0.8, stroke-width: 1
      axion-magenta = color: #ec95ec, label: #e8f6f5, shadow: #000000, shadow-opacity: 0.4, stroke: #d486d4, stroke-opacity: 0.8, stroke-width: 1
      axion-purple = color: #80638e, label: #e8f6f5, shadow: #000000, shadow-opacity: 0.4, stroke: #d486d4, stroke-opacity: 0.8, stroke-width: 1
      sizes = 24, 30, 32, 48
    '';
  };
in {
  home.sessionVariables = {
    EDITOR = "zed";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "ghostty";
    VISUAL = "zed";
    XDG_TERMINAL_EDITOR = "ghostty";
    XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:$HOME/.local/share:$XDG_DATA_DIRS";
  };

  xdg.desktopEntries = {
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

  home.pointerCursor = {
    package = axion-cursors;
    name = "oreo_axion-magenta_cursors";
    size = 30;
    gtk.enable = true;
    x11.enable = true;
  };

  # XDG MIME type associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = ["nemo.desktop"];
      "inode/blockdevice" = ["nemo.desktop"];

      # Images - qView
      "image/bmp" = ["com.interversehq.qView.desktop"];
      "image/gif" = ["com.interversehq.qView.desktop"];
      "image/jpeg" = ["com.interversehq.qView.desktop"];
      "image/jpg" = ["com.interversehq.qView.desktop"];
      "image/png" = ["com.interversehq.qView.desktop"];
      "image/svg+xml" = ["com.interversehq.qView.desktop"];
      "image/tiff" = ["com.interversehq.qView.desktop"];
      "image/webp" = ["com.interversehq.qView.desktop"];

      "audio/aac" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/flac" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/mp3" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/mpeg" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/ogg" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/wav" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/webm" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/x-opus+ogg" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/x-vorbis+ogg" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/x-mpegurl" = ["io.github.htkhiem.Euphonica.desktop"];
      "audio/mpegurl" = ["io.github.htkhiem.Euphonica.desktop"];
      "application/vnd.apple.mpegurl" = ["io.github.htkhiem.Euphonica.desktop"];
      "application/x-mpegurl" = ["io.github.htkhiem.Euphonica.desktop"];
      "application/x-mpegURL" = ["io.github.htkhiem.Euphonica.desktop"];

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

      # Web - Brave
      "text/html" = ["brave-browser.desktop"];
      "x-scheme-handler/http" = ["brave-browser.desktop"];
      "x-scheme-handler/https" = ["brave-browser.desktop"];

      # Terminal
      "application/x-terminal-emulator" = ["com.mitchellh.ghostty.desktop"];
      "x-scheme-handler/terminal" = ["com.mitchellh.ghostty.desktop"];

      # Torrents - Transmission
      "x-scheme-handler/magnet" = ["transmission-gtk.desktop"];
      "application/x-bittorrent" = ["transmission-gtk.desktop"];

      # Discord - Vesktop
      "x-scheme-handler/discord" = ["vesktop.desktop"];
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      icon-theme = "Adwaita";
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
