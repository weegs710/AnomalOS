{...}: {
  flake.nixosModules.xdg = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;

    phinger-cursors-dark-hyprcursor = pkgs.stdenvNoCC.mkDerivation {
      pname = "phinger-cursors-dark-hyprcursor";
      version = "2.1";

      src = ./phinger-cursors-dark-hyprcursor;

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
  in
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [
          pkgs.phinger-cursors
          pkgs.adw-gtk3
          phinger-cursors-dark-hyprcursor
        ];

        environment.sessionVariables = {
          EDITOR = "zed";
          NIXOS_OZONE_WL = "1";
          TERMINAL = "ghostty";
          VISUAL = "zed";
          XDG_TERMINAL_EDITOR = "ghostty";
          XDG_DATA_DIRS = [
            "$HOME/.local/share/flatpak/exports/share"
            "$HOME/.local/share"
          ];
          XCURSOR_PATH = ["${pkgs.phinger-cursors}/share/icons"];
        };

        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/interface" = {
                gtk-theme = "adw-gtk3";
                icon-theme = "Adwaita";
                color-scheme = "prefer-dark";
                cursor-theme = "phinger-cursors-dark";
                cursor-size = lib.gvariant.mkInt32 32;
              };
            };
          }
        ];

        hjem.users.${username} = {
          xdg.config.files = {
            "gtk-3.0/settings.ini".text = ''
              [Settings]
              gtk-cursor-theme-name=phinger-cursors-dark
              gtk-cursor-theme-size=32
              gtk-icon-theme-name=Adwaita
              gtk-theme-name=adw-gtk3
            '';

            "gtk-4.0/settings.ini".text = ''
              [Settings]
              gtk-cursor-theme-name=phinger-cursors-dark
              gtk-cursor-theme-size=32
              gtk-icon-theme-name=Adwaita
              gtk-theme-name=adw-gtk3
            '';

            "mimeapps.list".text = ''
              [Added Associations]

              [Default Applications]
              application/gzip=org.gnome.FileRoller.desktop
              application/pdf=org.pwmt.zathura-pdf-mupdf.desktop;org.kde.okular.desktop
              application/vnd.apple.mpegurl=io.github.htkhiem.Euphonica.desktop
              application/x-7z-compressed=org.gnome.FileRoller.desktop
              application/x-bittorrent=transmission-gtk.desktop
              application/x-mpegURL=io.github.htkhiem.Euphonica.desktop
              application/x-mpegurl=io.github.htkhiem.Euphonica.desktop
              application/x-rar=org.gnome.FileRoller.desktop
              application/x-shellscript=dev.zed.Zed.desktop
              application/x-tar=org.gnome.FileRoller.desktop
              application/x-terminal-emulator=com.mitchellh.ghostty.desktop
              application/zip=org.gnome.FileRoller.desktop
              audio/aac=io.github.htkhiem.Euphonica.desktop
              audio/flac=io.github.htkhiem.Euphonica.desktop
              audio/mp3=io.github.htkhiem.Euphonica.desktop
              audio/mpeg=io.github.htkhiem.Euphonica.desktop
              audio/mpegurl=io.github.htkhiem.Euphonica.desktop
              audio/ogg=io.github.htkhiem.Euphonica.desktop
              audio/wav=io.github.htkhiem.Euphonica.desktop
              audio/webm=io.github.htkhiem.Euphonica.desktop
              audio/x-mpegurl=io.github.htkhiem.Euphonica.desktop
              audio/x-opus+ogg=io.github.htkhiem.Euphonica.desktop
              audio/x-vorbis+ogg=io.github.htkhiem.Euphonica.desktop
              image/bmp=com.interversehq.qView.desktop
              image/gif=com.interversehq.qView.desktop
              image/jpeg=com.interversehq.qView.desktop
              image/jpg=com.interversehq.qView.desktop
              image/png=com.interversehq.qView.desktop
              image/svg+xml=com.interversehq.qView.desktop
              image/tiff=com.interversehq.qView.desktop
              image/webp=com.interversehq.qView.desktop
              text/html=zen.desktop
              text/markdown=dev.zed.Zed.desktop
              text/plain=dev.zed.Zed.desktop
              text/x-csrc=dev.zed.Zed.desktop
              text/x-python=dev.zed.Zed.desktop
              x-scheme-handler/discord=vesktop.desktop
              x-scheme-handler/http=zen.desktop
              x-scheme-handler/https=zen.desktop
              x-scheme-handler/magnet=transmission-gtk.desktop
              x-scheme-handler/terminal=com.mitchellh.ghostty.desktop

              [Removed Associations]
            '';
          };

          xdg.data.files = {
            "icons/default/index.theme".text = ''
              [Icon Theme]
              Name=Default
              Comment=Default Cursor Theme
              Inherits=phinger-cursors-dark
            '';

            # Hidden desktop entries — suppress defaults from app menu
            "applications/qt5ct.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Qt5 Settings
              Hidden=true
            '';
            "applications/qt6ct.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Qt6 Settings
              Hidden=true
            '';
            "applications/kvantummanager.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Kvantum Manager
              Hidden=true
            '';
            "applications/org.pulseaudio.pavucontrol.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=PulseAudio Volume Control
              Hidden=true
            '';
            "applications/org.freedesktop.Piper.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Piper
              Hidden=true
            '';

            # qView — registers image mime types, hidden from menu
            "applications/com.interversehq.qView.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=qView
              GenericName=Image Viewer
              Comment=Minimal image viewer
              Exec=qview %U
              Icon=com.interversehq.qView
              Hidden=true
              Categories=Qt;Graphics;Viewer;Photography;
              MimeType=image/bmp;image/x-win-bitmap;image/gif;image/icns;image/x-icon;image/jpeg;image/jpg;image/x-portable-bitmap;image/x-portable-graymap;image/png;image/x-portable-pixmap;image/svg+xml;image/tiff;image/vnd.wap.wbmp;image/webp;image/x-xbitmap;image/x-xpixmap;application/x-navi-animation;image/apng;image/avif;image/avif-sequence;image/x-sgi-bw;image/aces;image/x-exr;image/vnd.radiance;image/heic;image/heif;image/jxl;application/x-krita;image/openraster;image/vnd.zbrush.pcx;image/x-pcx;image/x-pic;image/vnd.adobe.photoshop;application/x-photoshop;application/photoshop;application/psd;image/psd;image/x-sun-raster;image/x-rgb;image/x-sgi-rgba;image/sgi;image/x-tga;image/x-xcf;
            '';

            # Custom launchers — open apps into specific workspaces/layouts via hyprctl
            "applications/pavucontrol.desktop".text = ''
              [Desktop Entry]
              Name=PulseAudio Volume Control
              GenericName=Volume Control
              Comment=Adjust the volume level
              Icon=multimedia-volume-control
              Exec=hyprctl dispatch exec '[workspace special:control-panel; float] pavucontrol'
              Terminal=false
              Type=Application
              Categories=AudioVideo;Audio;Mixer;GTK;
              Keywords=pavucontrol;audio;sound;volume;
            '';
            "applications/qalculate-gtk.desktop".text = ''
              [Desktop Entry]
              Name=Qalculate!
              GenericName=Calculator
              Comment=Powerful and easy to use calculator
              Icon=qalculate
              Exec=hyprctl dispatch exec '[workspace special:control-panel; float] qalculate-gtk'
              Terminal=false
              Type=Application
              Categories=Utility;Calculator;GTK;
              Keywords=calculator;math;
            '';
            "applications/piper.desktop".text = ''
              [Desktop Entry]
              Name=Piper
              GenericName=Gaming Mouse Configuration
              Comment=Configure gaming mice
              Icon=org.freedesktop.Piper
              Exec=hyprctl dispatch exec '[workspace special:control-panel; float] piper'
              Terminal=false
              Type=Application
              Categories=Settings;HardwareSettings;GTK;
              Keywords=gaming;mouse;configuration;
            '';
          };
        };
      };
    };
}
