{...}: {
  flake.nixosModules.xdg = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    homeDirectory = "/home/${username}";

    phinger-cursors-dark-hyprcursor = pkgs.stdenvNoCC.mkDerivation {
      pname = "phinger-cursors-dark-hyprcursor";
      version = "2.1";

      src = ./../../assets/cursors/phinger-cursors-dark-hyprcursor;

      dontBuild = true;

      installPhase = ''
        mkdir -p $out/share/icons/phinger-cursors-dark-hyprcursor
        cp -r $src/* $out/share/icons/phinger-cursors-dark-hyprcursor/
      '';

      meta = with lib; {
        description = "Phinger cursors dark variant in hyprcursor format";
        homepage = "https://github.com/phisch/phinger-cursors";
        license = licenses.cc-by-sa-40;
        platforms = platforms.linux;
      };
    };
  in {
    home-manager.users.${username} = {
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
          genericName = "Image Viewer";
          comment = "Minimal image viewer";
          exec = "qview %U";
          icon = "com.interversehq.qView";
          mimeType = [
            "image/bmp"
            "image/x-win-bitmap"
            "image/gif"
            "image/icns"
            "image/x-icon"
            "image/jpeg"
            "image/jpg"
            "image/x-portable-bitmap"
            "image/x-portable-graymap"
            "image/png"
            "image/x-portable-pixmap"
            "image/svg+xml"
            "image/tiff"
            "image/vnd.wap.wbmp"
            "image/webp"
            "image/x-xbitmap"
            "image/x-xpixmap"
            "application/x-navi-animation"
            "image/apng"
            "image/avif"
            "image/avif-sequence"
            "image/x-sgi-bw"
            "image/aces"
            "image/x-exr"
            "image/vnd.radiance"
            "image/heic"
            "image/heif"
            "image/jxl"
            "application/x-krita"
            "image/openraster"
            "image/vnd.zbrush.pcx"
            "image/x-pcx"
            "image/x-pic"
            "image/vnd.adobe.photoshop"
            "application/x-photoshop"
            "application/photoshop"
            "application/psd"
            "image/psd"
            "image/x-sun-raster"
            "image/x-rgb"
            "image/x-sgi-rgba"
            "image/sgi"
            "image/x-tga"
            "image/x-xcf"
          ];
          categories = ["Qt" "Graphics" "Viewer" "Photography"];
          noDisplay = true;
        };
      };

      home.pointerCursor = {
        package = pkgs.phinger-cursors;
        name = "phinger-cursors-dark";
        size = 32;
        gtk.enable = true;
        x11.enable = true;

        hyprcursor = {
          enable = true;
          size = 32;
        };
      };

      home.packages = [
        phinger-cursors-dark-hyprcursor
      ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
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
          "application/pdf" = ["org.pwmt.zathura-pdf-mupdf.desktop"];
          "text/plain" = ["dev.zed.Zed.desktop"];
          "text/markdown" = ["dev.zed.Zed.desktop"];
          "text/x-csrc" = ["dev.zed.Zed.desktop"];
          "text/x-python" = ["dev.zed.Zed.desktop"];
          "application/x-shellscript" = ["dev.zed.Zed.desktop"];
          "application/zip" = ["org.gnome.FileRoller.desktop"];
          "application/x-7z-compressed" = ["org.gnome.FileRoller.desktop"];
          "application/x-rar" = ["org.gnome.FileRoller.desktop"];
          "application/x-tar" = ["org.gnome.FileRoller.desktop"];
          "application/gzip" = ["org.gnome.FileRoller.desktop"];
          "text/html" = ["zen.desktop"];
          "x-scheme-handler/http" = ["zen.desktop"];
          "x-scheme-handler/https" = ["zen.desktop"];
          "application/x-terminal-emulator" = ["com.mitchellh.ghostty.desktop"];
          "x-scheme-handler/terminal" = ["com.mitchellh.ghostty.desktop"];
          "x-scheme-handler/magnet" = ["transmission-gtk.desktop"];
          "application/x-bittorrent" = ["transmission-gtk.desktop"];
          "x-scheme-handler/discord" = ["vesktop.desktop"];
        };
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          icon-theme = "Adwaita";
          gtk-theme = "adw-gtk3";
          color-scheme = "prefer-dark";
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
      };
    };
  };
}
