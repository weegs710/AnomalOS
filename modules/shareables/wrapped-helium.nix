{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    # Widevine is unfree and requires allowUnfree in perSystem context
    pkgsUnfree = import pkgs.path {
      inherit system;
      config.allowUnfree = true;
    };

    extensionPolicy = pkgs.writeText "policy.json" (builtins.toJSON {
      # IDs only (no URLs) to avoid triggering TRK protocol blocking
      ExtensionInstallForcelist = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "agleiimpggapjekcdhdjbmegjbbkleie" # Ground News
        "neebplgakaahbhdphmkckjjcegoiijjo" # Keepa
        "odibgflepadohfmpcemnjbhkionjkapk" # Helium Translator Inline
      ];
    });

    initialPreferences = pkgs.writeText "initial_preferences" (builtins.toJSON {
      helium = {
        services = {
          enabled = true;
          user_consented = true;
        };
      };
    });

    policiesDir = pkgs.runCommand "helium-policies" {} ''
      mkdir -p $out/etc/opt/chrome/policies/managed
      cp ${extensionPolicy} $out/etc/opt/chrome/policies/managed/extensions.json
    '';

    widevineConfig = pkgs.writeText "latest-component-updated-widevine-cdm" (builtins.toJSON {
      Path = "${pkgsUnfree.widevine-cdm}/share/google/chrome/WidevineCdm";
    });

    # Tarball allows more control than AppImage
    heliumPkg = pkgs.stdenv.mkDerivation rec {
      pname = "helium";
      version = "0.8.5.1";

      src = pkgs.fetchurl {
        url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-x86_64_linux.tar.xz";
        sha256 = "sha256-/cp201tiw2N+xsj89Ms06efJyYnfgc04uoJnvsjDUog=";
      };

      nativeBuildInputs = with pkgs; [
        makeWrapper
        autoPatchelfHook
      ];

      buildInputs = with pkgs; [
        stdenv.cc.cc.lib
        gtk3
        nss
        nspr
        alsa-lib
        cups
        libdrm
        mesa
        expat
        libxkbcommon
        pango
        cairo
        at-spi2-atk
        at-spi2-core
        dbus
        libva
        libGL
      ];

      # Qt shim libraries are optional compatibility layers
      autoPatchelfIgnoreMissingDeps = [
        "libQt5Core.so.5"
        "libQt5Gui.so.5"
        "libQt5Widgets.so.5"
        "libQt6Core.so.6"
        "libQt6Gui.so.6"
        "libQt6Widgets.so.6"
      ];

      sourceRoot = "helium-${version}-x86_64_linux";

      installPhase = ''
        mkdir -p $out/opt/helium $out/bin

        cp -r . $out/opt/helium/
        chmod +x $out/opt/helium/helium

        makeWrapper $out/opt/helium/helium $out/bin/helium \
          --add-flags "--enable-features=VaapiVideoDecoder,WebUIDarkMode,HeliumCatUi,HideCrashedBubble,LinkPreview" \
          --add-flags "--disable-features=EyeDropper,HeliumCatFixedAddressBar"

        mkdir -p $out/share/applications
        cp $out/opt/helium/helium.desktop $out/share/applications/
        substituteInPlace $out/share/applications/helium.desktop \
          --replace 'Exec=helium' 'Exec=${pname}'

        for size in 16 32 48 64 128 256; do
          mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
          if [ -f $out/opt/helium/product_logo_''${size}.png ]; then
            cp $out/opt/helium/product_logo_''${size}.png \
               $out/share/icons/hicolor/''${size}x''${size}/apps/helium.png
          fi
        done
      '';

      meta = {
        description = "Private, fast, and honest web browser";
        homepage = "https://helium.computer/";
        platforms = [ "x86_64-linux" ];
      };
    };

    heliumWrapper = pkgs.writeShellScript "helium-wrapper" ''
      USER_DATA_DIR=""
      for arg in "$@"; do
        if [[ "$arg" == --user-data-dir=* ]]; then
          USER_DATA_DIR="''${arg#*=}"
          break
        fi
      done

      if [ -z "$USER_DATA_DIR" ]; then
        USER_DATA_DIR="$HOME/.config/helium"
      fi

      mkdir -p "$USER_DATA_DIR/WidevineCdm"
      cp ${widevineConfig} "$USER_DATA_DIR/WidevineCdm/latest-component-updated-widevine-cdm"

      exec ${heliumPkg}/bin/helium "$@"
    '';

    wrappedHelium = pkgs.buildFHSEnv {
      name = "helium";
      targetPkgs = pkgs: [
        heliumPkg
      ];
      extraBwrapArgs = [
        "--ro-bind ${policiesDir}/etc/opt/chrome/policies/managed /etc/chromium/policies/managed"
      ];
      runScript = heliumWrapper;
      extraInstallCommands = ''
        mkdir -p $out/share/applications
        cp ${heliumPkg}/share/applications/helium.desktop $out/share/applications/

        for size in 16 32 48 64 128 256; do
          mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
          if [ -f ${heliumPkg}/share/icons/hicolor/''${size}x''${size}/apps/helium.png ]; then
            cp ${heliumPkg}/share/icons/hicolor/''${size}x''${size}/apps/helium.png \
               $out/share/icons/hicolor/''${size}x''${size}/apps/
          fi
        done
      '';
      meta = {
        mainProgram = "helium";
        description = "Helium browser with DRM, dark UI, and bundled extensions";
      };
    };
  in {
    packages.helium = wrappedHelium;
  };
}
