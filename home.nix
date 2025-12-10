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

  stylix.enableReleaseChecks = false;

  programs.claude-code-enhanced.enable = true;

  programs.fish = {
    enable = true;

    functions = {
      kc-send = {
        description = "Send files to paired KDE Connect device";
        body = ''
          set device_id (kdeconnect-cli --list-available | grep -oP '(?<=: )[a-f0-9]+(?= \(paired)')

          if test -z "$device_id"
              echo "No paired device found"
              return 1
          end

          for item in $argv
              if test -f $item
                  echo "Sending: $item"
                  kdeconnect-cli -d $device_id --share $item
              else if test -d $item
                  echo "Sending all files from directory: $item"
                  for file in $item/*
                      if test -f $file
                          echo "  Sending: $file"
                          kdeconnect-cli -d $device_id --share $file
                      end
                  end
              else
                  echo "Skipping: $item (not found or not accessible)"
              end
          end
        '';
      };
    };

    plugins = [
      # fzf integration - fuzzy finder for history, files, git
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }

      # Directory jumping - tracks and jumps to frequently used directories
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }

      # Notifications for long-running commands
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }

      # Colorize man pages
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }

      # Auto-close quotes, parentheses, brackets
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair-fish.src;
      }

      # Remove failed commands from history
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }

      # Interactive git operations with fzf
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
    ];

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
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default
    alejandra
    cliphist
    ed-odyssey-materials-helper
    edmarketconnector
    fastfetch
    fzf
    gh
    glow
    gparted
    grim
    hyprls
    hyprshot
    jq
    min-ed-launcher
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
    TERMINAL = "ghostty";
    VISUAL = "zed";
    XDG_TERMINAL_EDITOR = "ghostty";
    XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:$HOME/.local/share:$XDG_DATA_DIRS";
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
      "audio/x-mpegurl" = ["vlc.desktop"];
      "audio/mpegurl" = ["vlc.desktop"];
      "application/vnd.apple.mpegurl" = ["vlc.desktop"];
      "application/x-mpegurl" = ["vlc.desktop"];

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

  programs.home-manager.enable = true;

  # Claude Code project directory (conditional)
  home.file."claude-projects/.keep" = lib.mkIf osConfig.mySystem.features.claudeCode {
    text = "";
  };

  home.file.".local/share/min-ed-launcher/MinEdLauncher" = {
    source = "${pkgs.min-ed-launcher}/bin/MinEdLauncher";
  };

  home.activation.minEdLauncherSymlink = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "/mnt/kingston-1tb/steamapps/common/Elite Dangerous"
    $DRY_RUN_CMD ln -sf "${config.home.homeDirectory}/.local/share/min-ed-launcher/MinEdLauncher" \
      "/mnt/kingston-1tb/steamapps/common/Elite Dangerous/MinEdLauncher"
  '';
}
