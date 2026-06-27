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
    EDITOR = "zeditor --wait";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "ghostty";
    VISUAL = "zeditor --wait";
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
      "gtk-3.0/settings.ini".source = ./gtk3-settings.ini;
      "gtk-4.0/settings.ini".source = ./gtk4-settings.ini;
      "mimeapps.list".source = ./mimeapps.list;
    };

    xdg.data.files = {
      "icons/default/index.theme".source = ./index.theme;
      "applications/yazi.desktop".source = ./yazi.desktop;
      # Custom launcher -- opens piper into special:stash workspace via hyprctl (see piper.desktop Exec)
      "applications/piper.desktop".source = ./piper.desktop;
    };
  };
}
