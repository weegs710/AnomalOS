{
  config,
  pkgs,
  only,
  ...
}:
let
  gpartedWithTools = pkgs.gparted.override { withAllTools = true; };
  # IFF (libiff, unmaintained) and FITS (cfitsio) loaders carry unfixed CVEs and go unused here
  gimpWithPlugins = pkgs.gimp-with-plugins.override {
    gimpPlugins = pkgs.gimpPlugins.override {
      gimp = pkgs.gimp.overrideAttrs (old: {
        mesonFlags = old.mesonFlags ++ [
          "-Dilbm=disabled"
          "-Dfits=disabled"
        ];
      });
    };
  };
  ueberzugppNoFits = pkgs.ueberzugpp.override {
    vips = pkgs.vips.overrideAttrs (old: {
      mesonFlags = old.mesonFlags ++ [ "-Dcfitsio=disabled" ];
    });
  };
  # env set inside the sudo shell -- PAM clobbers XDG_DATA_DIRS back to root's profile otherwise, hiding the user's theme
  gpartedSafe = pkgs.writeShellScriptBin "gparted-safe" ''
    trap 'systemctl --user start udiskie' EXIT
    systemctl --user stop udiskie
    sudo sh -c "export GDK_BACKEND=wayland WAYLAND_DISPLAY='$WAYLAND_DISPLAY' XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR' GTK_THEME=adw-gtk3-dark XDG_CONFIG_HOME='$HOME/.config' XDG_DATA_DIRS='$XDG_DATA_DIRS'; exec ${gpartedWithTools}/bin/gparted"
  '';
  # pinned to the google/fonts rev nixpkgs' google-fonts uses, which ships only the variable file
  spaceGroteskVariable = pkgs.fetchurl {
    name = "SpaceGrotesk-wght.ttf";
    url = "https://raw.githubusercontent.com/google/fonts/5174b3333331c966c38f4355d50b03ca1c1df2f9/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf";
    hash = "sha256-rK1t4fyTQ29cDx9BN3Ue8E8a6jBj5wNlNZcP/PvXn3I=";
  };
  # nerd-font-patcher segfaults on the variable file, so static weights are cut first
  spaceGroteskNerd =
    pkgs.runCommand "space-grotesk-nerd-font"
      {
        nativeBuildInputs = [
          pkgs.nerd-font-patcher
          pkgs.python3Packages.fonttools
        ];
      }
      ''
        mkdir static
        dest=$out/share/fonts/truetype/NerdFonts/SpaceGrotesk
        mkdir -p $dest
        for w in 300 400 500 700; do
          fonttools varLib.instancer ${spaceGroteskVariable} wght=$w --update-name-table -o static/SpaceGrotesk-$w.ttf
          nerd-font-patcher --complete --variable-width-glyphs --quiet --outputdir $dest static/SpaceGrotesk-$w.ttf
        done
      '';
  # Space Mono ships no programming ligatures, so the arrow, comparison, pipe and bind set is drawn from its own glyphs
  spaceMonoLigatures =
    pkgs.runCommand "space-mono-nerd-font-ligatures"
      {
        nativeBuildInputs = [
          (pkgs.python3.withPackages (p: [
            p.fonttools
            p.skia-pathops
          ]))
        ];
      }
      ''
        src=${pkgs.nerd-fonts.space-mono}/share/fonts/truetype/NerdFonts/SpaceMono
        dest=$out/share/fonts/truetype/NerdFonts/SpaceMono
        mkdir -p $dest
        cp $src/*.ttf $dest/
        chmod u+w $dest/*.ttf
        for w in Regular Italic Bold BoldItalic; do
          python3 ${./space-mono-ligatures.py} $src/SpaceMonoNerdFontMono-$w.ttf $dest/SpaceMonoNerdFontMono-$w.ttf
        done
      '';
in
# gated so a headless host skips the whole desktop bundle rather than pulling GUI packages it never starts
only.gate { tags = [ "desktop" ]; }
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    adwaita-icon-theme
    bluetui
    cachix
    tutanota-desktop
    zathura
    dbus
    dbus-broker
    file-roller
    gpartedWithTools
    gpartedSafe
    libGL
    libnotify
    libportal
    libx11
    libxcursor
    libxi
    libxinerama
    libxrandr
    libxxf86vm
    lm_sensors
    mesa
    qalculate-gtk
    qview
    tremc
    ueberzugppNoFits
    unzipNLS
    xdg-dbus-proxy
    gimpWithPlugins
    gpu-screen-recorder
    ffmpeg
    inkscape
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.shellAliases = {
    gparted = "gparted-safe";
  };

  fonts.packages =
    with pkgs.nerd-fonts;
    [
      dejavu-sans-mono
      jetbrains-mono
      fira-code
      terminess-ttf
      hack
      iosevka
    ]
    ++ [
      pkgs.noto-fonts-color-emoji
      spaceGroteskNerd
      spaceMonoLigatures
    ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/tutanota-desktop"
    ".config/qView"
    ".config/zathura"
    ".config/cachix"
    ".local/share/zathura"
    ".local/share/bluetui"
  ];

  programs.gpu-screen-recorder.enable = true;
  programs.gnome-disks.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General.Experimental = true;

  services.blueman.enable = true;
  services.upower.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.locate = {
    enable = true;
    # the db is ~60M; plocate reads a compiled-in /var/cache/locatedb, so that path links to disk
    output = "/cache/var/cache/locatedb";
  };
  systemd.tmpfiles.rules = [ "L+ /var/cache/locatedb - - - - /cache/var/cache/locatedb" ];
  services.speechd.enable = false; # pulled in as a gnome dependency, not needed

  services.displayManager = {
    defaultSession = "umbriel";
    noctalia-greeter = {
      enable = true;
      # Stock greeter answers the first PAM prompt with an empty submit, which starves pam_unix's fallback behind the u2f cue.
      # See: https://github.com/noctalia-dev/noctalia-greeter/issues/90
      package = pkgs.noctalia-greeter.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./noctalia-greeter-empty-submit-patch ];
      });
      settings = {
        session.default = "Umbriel";
        auth.allow_empty_password = true;
      };
      # noctalia auto-syncs on every wallpaper rotation, which would otherwise demand auth each time
      passwordlessSyncUsers = [ config.mySystem.user.name ];
    };
  };

  # ids pinned for users owning persisted state so allocation order can never reassign them
  users.users.greeter.uid = 984;
  users.groups.greeter.gid = 979;

  preservation.preserveAt."/persist".directories = [
    # sync.toml + wallpaper copies, so the greeter boots wearing the last synced look
    {
      directory = "/var/lib/noctalia-greeter";
      user = "greeter";
      group = "greeter";
      mode = "0750";
    }
    "/var/lib/bluetooth"
  ];
}
