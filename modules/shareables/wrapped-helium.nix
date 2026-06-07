{ pkgs, ... }:
let
  widevineConfig = pkgs.writeText "latest-component-updated-widevine-cdm" (
    builtins.toJSON {
      Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm";
    }
  );

  heliumPkg = pkgs.stdenv.mkDerivation rec {
    pname = "helium";
    version = "0.10.7.1";

    src = pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-x86_64_linux.tar.xz";
      sha256 = "sha256-ZHziopdl8ClZQJUHXtIIb9ok/flZoixMdlLMKf5HUUo=";
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

    # helium ships Qt shim stubs that autoPatchelf cannot satisfy; absence is intentional
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

      makeWrapper $out/opt/helium/helium $out/bin/helium

      mkdir -p $out/share/applications
      cp $out/opt/helium/helium.desktop $out/share/applications/

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

  # --policy-dir and user-flags only fire when the hjem module has populated those paths
  heliumWrapper = pkgs.writeShellScript "helium-wrapper" ''
    USER_DATA_DIR=""
    for arg in "$@"; do
      if [[ "$arg" == --user-data-dir=* ]]; then
        USER_DATA_DIR="''${arg#*=}"
        break
      fi
    done

    if [ -z "$USER_DATA_DIR" ]; then
      USER_DATA_DIR="$HOME/.config/net.imput.helium"
    fi

    mkdir -p "$USER_DATA_DIR/WidevineCdm"
    cp ${widevineConfig} "$USER_DATA_DIR/WidevineCdm/latest-component-updated-widevine-cdm"
    chmod u+w "$USER_DATA_DIR/WidevineCdm/latest-component-updated-widevine-cdm"

    POLICY_FLAGS=""
    if [ -d "$HOME/.config/net.imput.helium/policies" ]; then
      POLICY_FLAGS="--policy-dir=$HOME/.config/net.imput.helium/policies"
    fi

    USER_FLAGS=""
    if [ -f "$HOME/.config/net.imput.helium/user-flags" ]; then
      USER_FLAGS=$(cat "$HOME/.config/net.imput.helium/user-flags")
    fi

    exec ${heliumPkg}/bin/helium $POLICY_FLAGS $USER_FLAGS "$@"
  '';

  wrappedHelium = pkgs.buildFHSEnv {
    name = "helium";
    targetPkgs = _pkgs: [
      heliumPkg
      pkgs.mesa
      pkgs.libGL
      pkgs.libdrm
      pkgs.libva
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
      description = "Helium browser with Widevine DRM";
    };
  };
in
{
  helium = wrappedHelium;
}
