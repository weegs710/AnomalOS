{
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    version = "1.19.5b";
    binaryName = "zen";
    libName = "zen-bin-${version}";

    zenUnwrapped = pkgs.stdenv.mkDerivation {
      pname = "zen-browser-unwrapped";
      inherit version;

      src = pkgs.fetchzip {
        url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
        hash = "sha256-9egQHSYVEHfFokv6ti6VJeiz/N1vQQg5TQhivp+f1wk=";
      };

      nativeBuildInputs = with pkgs; [
        wrapGAppsHook3
        autoPatchelfHook
        patchelfUnstable
        copyDesktopItems
      ];

      buildInputs = with pkgs; [
        gtk3
        adwaita-icon-theme
        alsa-lib
        dbus-glib
        libXtst
        ffmpeg_7
      ];

      runtimeDependencies = with pkgs; [
        curl
        libva.out
        pciutils
        libGL
      ];

      appendRunpaths = with pkgs; [
        "${libGL}/lib"
        "${pipewire}/lib"
      ];

      # Firefox uses "relrhack" to manually process relocations from a fixed offset
      # See: https://github.com/0xc000022070/zen-browser-flake/blob/main/package.nix
      patchelfFlags = ["--no-clobber-old-sections"];

      desktopItems = [
        (pkgs.makeDesktopItem {
          name = binaryName;
          desktopName = "Zen Browser";
          exec = "${binaryName} %u";
          icon = "zen-browser";
          type = "Application";
          mimeTypes = [
            "text/html"
            "text/xml"
            "application/xhtml+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "application/x-xpinstall"
            "application/pdf"
            "application/json"
          ];
          startupWMClass = binaryName;
          categories = ["Network" "WebBrowser"];
          startupNotify = true;
          terminal = false;
          keywords = ["Internet" "WWW" "Browser" "Web" "Explorer"];
          actions = {
            new-window = {
              name = "Open a New Window";
              exec = "${binaryName} %u";
            };
            new-private-window = {
              name = "Open a New Private Window";
              exec = "${binaryName} --private-window %u";
            };
            profilemanager = {
              name = "Open the Profile Manager";
              exec = "${binaryName} --ProfileManager %u";
            };
          };
        })
      ];

      preFixup = ''
        gappsWrapperArgs+=(
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.ffmpeg_7]}"
          --add-flags "--name=''${MOZ_APP_LAUNCHER:-${binaryName}}"
          --add-flags "--class=''${MOZ_APP_LAUNCHER:-${binaryName}}"
        )
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/${libName}
        cp -r . $out/lib/${libName}

        mkdir -p $out/bin
        ln -s $out/lib/${libName}/zen $out/bin/${binaryName}

        install -D browser/chrome/icons/default/default16.png $out/share/icons/hicolor/16x16/apps/zen-browser.png
        install -D browser/chrome/icons/default/default32.png $out/share/icons/hicolor/32x32/apps/zen-browser.png
        install -D browser/chrome/icons/default/default48.png $out/share/icons/hicolor/48x48/apps/zen-browser.png
        install -D browser/chrome/icons/default/default64.png $out/share/icons/hicolor/64x64/apps/zen-browser.png
        install -D browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen-browser.png

        runHook postInstall
      '';

      passthru = {
        inherit binaryName libName;
        applicationName = "Zen Browser";
        ffmpegSupport = true;
        gssSupport = true;
        gtk3 = pkgs.gtk3;
      };

      meta = {
        description = "Experience tranquillity while browsing the web without people tracking you!";
        homepage = "https://zen-browser.app";
        platforms = ["x86_64-linux"];
        mainProgram = binaryName;
      };
    };

    wrappedZen = pkgs.wrapFirefox zenUnwrapped {
      icon = "zen-browser";
      extraPolicies = {
        # Disable in-browser update prompts; Nix manages the version
        DisableAppUpdate = true;
      };
      # Plug Firefox-inherited connection gaps not covered by Zen's privatefox prefs
      extraPrefs = ''
        lockPref("network.captive-portal-service.enabled", false);
        lockPref("network.connectivity-service.enabled", false);
        lockPref("geo.enabled", false);
        lockPref("dom.push.connection.enabled", false);
        lockPref("browser.urlbar.merino-online-suggestions.enabled", false);
        lockPref("browser.urlbar.quicksuggest.enabled", false);
      '';
    };
  in {
    packages.zen = wrappedZen;
  };
}
