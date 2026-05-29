{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;

  fft-ivalice-hyprcursor = pkgs.stdenvNoCC.mkDerivation {
    pname = "fft-ivalice-hyprcursor";
    version = "1.0";

    src = inputs.fft-ivalice-cursor;

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/icons/fft-ivalice-hyprcursor
      cp -r $src/* $out/share/icons/fft-ivalice-hyprcursor/
    '';

    meta = with lib; {
      description = "Cursor theme extracted from Final Fantasy Tactics - The Ivalice Chronicles";
      platforms = platforms.linux;
    };
  };

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
{
  users.users.${username}.packages = [
    pkgs.phinger-cursors
    pkgs.adw-gtk3
    phinger-cursors-dark-hyprcursor
    fft-ivalice-hyprcursor
  ];

  environment.sessionVariables = {
    EDITOR = "emacsclient -nw";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "ghostty";
    VISUAL = "emacsclient";
    XDG_TERMINAL_EDITOR = "ghostty";
    XDG_DATA_DIRS = [
      "$HOME/.local/share"
    ];
    XCURSOR_PATH = [ "${pkgs.phinger-cursors}/share/icons" ];
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
        inode/directory=nemo.desktop
        inode/mount-point=nemo.desktop
        application/pdf=org.pwmt.zathura-pdf-mupdf.desktop
        application/vnd.apple.mpegurl=rmpc-open.desktop
        application/x-7z-compressed=org.gnome.FileRoller.desktop
        application/x-bittorrent=transmission-add.desktop
        application/x-mpegurl=rmpc-open.desktop
        application/x-rar=org.gnome.FileRoller.desktop
        application/x-tar=org.gnome.FileRoller.desktop
        application/x-terminal-emulator=com.mitchellh.ghostty.desktop
        application/xml=emacsclient.desktop
        application/zip=org.gnome.FileRoller.desktop
        audio/aac=rmpc-open.desktop
        audio/flac=rmpc-open.desktop
        audio/mpeg=rmpc-open.desktop
        audio/mpegurl=rmpc-open.desktop
        audio/ogg=rmpc-open.desktop
        audio/wav=rmpc-open.desktop
        audio/webm=rmpc-open.desktop
        audio/x-mpegurl=rmpc-open.desktop
        audio/x-opus+ogg=rmpc-open.desktop
        audio/x-vorbis+ogg=rmpc-open.desktop
        image/bmp=com.interversehq.qView.desktop
        image/gif=com.interversehq.qView.desktop
        image/jpeg=com.interversehq.qView.desktop
        image/png=com.interversehq.qView.desktop
        image/svg+xml=com.interversehq.qView.desktop
        image/tiff=com.interversehq.qView.desktop
        image/webp=com.interversehq.qView.desktop
        text/html=zen.desktop
        text/plain=emacsclient.desktop
        text/xml=emacsclient.desktop
        video/3gpp=mpv.desktop
        video/3gpp2=mpv.desktop
        video/divx=mpv.desktop
        video/mp2t=mpv.desktop
        video/mp4=mpv.desktop
        video/mpeg=mpv.desktop
        video/ogg=mpv.desktop
        video/quicktime=mpv.desktop
        video/webm=mpv.desktop
        video/x-divx=mpv.desktop
        video/x-flv=mpv.desktop
        video/x-m4v=mpv.desktop
        video/x-matroska=mpv.desktop
        video/x-ms-asf=mpv.desktop
        video/x-ms-wmv=mpv.desktop
        video/x-msvideo=mpv.desktop
        video/x-ogm=mpv.desktop
        x-scheme-handler/http=zen.desktop
        x-scheme-handler/https=zen.desktop
        x-scheme-handler/magnet=transmission-add.desktop
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

      # Custom launchers — open apps into specific workspaces/layouts via hyprctl
      "applications/piper.desktop".text = ''
        [Desktop Entry]
        Name=Piper
        GenericName=Gaming Mouse Configuration
        Comment=Configure gaming mice
        Icon=org.freedesktop.Piper
        Exec=hyprctl dispatch exec '[workspace special:stash; tile] piper'
        Terminal=false
        Type=Application
        Categories=Settings;HardwareSettings;GTK;
        Keywords=gaming;mouse;configuration;
      '';
    };
  };
}
