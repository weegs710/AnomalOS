{ inputs, ... }:
{
  flake.nixosModules.xdg =
    {
      config,
      lib,
      pkgs,
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
        EDITOR = "fresh";
        NIXOS_OZONE_WL = "1";
        TERMINAL = "ghostty";
        VISUAL = "fresh";
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
            application/x-bittorrent=transmission-gtk.desktop
            application/x-mpegurl=rmpc-open.desktop
            application/x-rar=org.gnome.FileRoller.desktop
            application/x-tar=org.gnome.FileRoller.desktop
            application/x-terminal-emulator=com.mitchellh.ghostty.desktop
            application/xml=fresh.desktop
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
            text/plain=fresh.desktop
            text/xml=fresh.desktop
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

          # fresh — terminal text editor with LSP support
          "applications/fresh.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=Fresh
            GenericName=Text Editor
            Comment=Terminal-based text editor with LSP support and TypeScript plugins
            Exec=ghostty -e fresh %F
            Icon=text-editor
            Terminal=false
            Categories=Development;TextEditor;Utility;
            MimeType=text/plain;text/x-agda;text/x-astro;text/x-awk;text/x-sh;text/x-shellscript;text/x-c;text/x-csrc;text/x-chdr;text/x-csharp;text/x-cmake;text/x-common-lisp;text/x-log;application/x-wine-extension-ini;text/x-c++;text/x-c++src;text/x-c++hdr;application/x-csproj;text/css;text/x-patch;text/x-diff;text/dockerfile;text/x-dtd;text/x-elixir;text/x-elm;text/x-fish;text/x-fsharp;text/x-go;text/x-go-mod;text/x-hare;text/x-haskell;text/x-terraform;text/html;text/x-hurl;text/x-java;text/javascript;application/json;text/x-julia;text/x-kdl;text/x-tex;text/x-latex;text/x-lua;text/x-email;text/x-makefile;text/markdown;text/x-nasm;text/x-nickel;text/x-nim;text/x-nimble;text/x-ninja;text/x-nix;text/x-nushell;text/x-ocaml;text/x-odin;text/x-openscad;text/x-org;text/x-perl;text/x-php;text/x-gettext-translation;text/x-powershell;text/x-protobuf;text/x-purescript;text/x-python;text/x-python3;application/x-python;text/x-rpm-spec;text/x-rst;text/x-ruby;text/x-rustsrc;text/x-rust;text/x-scheme;text/x-sql;text/x-sshconfig;text/x-swift;application/toml;text/x-toml;text/typescript;application/x-typescript;text/x-typst;text/x-verilog;text/x-vim;text/xml;application/xml;text/yaml;application/x-yaml;text/x-zig;application/x-shellscript;
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
    };
}
