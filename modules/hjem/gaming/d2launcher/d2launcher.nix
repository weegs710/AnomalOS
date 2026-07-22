{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;

  sources = import ../../../../_sources/generated.nix { inherit (pkgs) fetchgit fetchurl fetchFromGitHub dockerTools; };

  # MXL's Fog.dll stack-overflows on wine 10/11; nixpkgs ships 11, so wrap Kron4ek proton-8.0-2 (wine-staging 8.0) in an FHS env that supplies the 32-bit loader + freetype a bare run lacks
  wineKron = pkgs.stdenvNoCC.mkDerivation {
    pname = "wine-proton-kron4ek";
    version = "8.0-2";
    src = pkgs.fetchurl {
      url = "https://github.com/Kron4ek/Wine-Builds/releases/download/proton-8.0-2/wine-proton-8.0-2-amd64.tar.xz";
      hash = "sha256-+8gLGn81n3Kln1SIIJHT2LhZ1FC0kxNthRzIOC6h2V0=";
    };
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  wineFhsLibs =
    p: with p; [
      freetype
      fontconfig
      libx11
      libxext
      libxcursor
      libxrandr
      libxi
      libxrender
      libxfixes
      libxcomposite
      libxcb
      libxxf86vm
      libGL
      libglvnd
      vulkan-loader
      alsa-lib
      libpulseaudio
      gnutls
      zlib
      stdenv.cc.cc.lib
    ];

  # multiArch=true is what installs the 32-bit ld-linux the proton build's 32-bit wine needs
  wine = pkgs.buildFHSEnv {
    name = "wine";
    multiArch = true;
    targetPkgs = wineFhsLibs;
    multiPkgs = wineFhsLibs;
    runScript = "${wineKron}/bin/wine";
  };

  zenity = pkgs.zenity;

  runtimeDeps = [
    pkgs.bash
    pkgs.coreutils
    pkgs.gnutar
    pkgs.gnused
    pkgs.gawk
    pkgs.gnugrep
    pkgs.findutils
    pkgs.procps
    pkgs.curl
    pkgs.unzip
    pkgs.zip
    pkgs.jq
    pkgs.zenity
    pkgs.libnotify
    pkgs.wmctrl
    pkgs.xdg-utils
    wine
  ];

  d2launcher = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "d2launcher";
    version = sources.d2launcher.version;

    src = sources.d2launcher.src;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/d2launcher $out/share/applications
      cp -r res $out/share/d2launcher/res
      install -Dm755 d2launcher $out/bin/d2launcher

      # lives inside the package so Exec/Icon always point at the current build, never a stale hash
      cat > $out/share/applications/d2launcher.desktop <<EOF
      [Desktop Entry]
      Name=Diablo II
      Icon=$out/share/d2launcher/res/icon.svg
      Exec=$out/bin/d2launcher
      Type=Application
      Terminal=false
      StartupWMClass=zenity
      Categories=Game;
      EOF

      # zenity is called by absolute path: the script's own zenity() wrapper function shadows the bare name and breaks command -v
      substituteInPlace $out/bin/d2launcher \
        --replace-fail '#!/usr/bin/env bash' '#!/usr/bin/env bash
      export PATH=${lib.makeBinPath runtimeDeps}:$PATH' \
        --replace-fail 'command -v /bin/zenity' 'command -v ${zenity}/bin/zenity' \
        --replace-fail '/usr/bin/zenity' '${zenity}/bin/zenity' \
        --replace-fail '/bin/notify-send' 'notify-send' \
        --replace-fail 'SCRIPT_RES_DIR="$WORKING_DIR/res"' 'SCRIPT_RES_DIR="'$out'/share/d2launcher/res"' \
        --replace-fail 'wine_default="$WINE_NATIVE_BIN"' 'wine_default="${wine}/bin/wine"'

      runHook postInstall
    '';

    meta = {
      description = "Diablo II / Median XL launcher for Linux, wrapped for NixOS";
      homepage = "https://github.com/murkl/d2launcher";
      license = lib.licenses.gpl3Only;
      mainProgram = "d2launcher";
      platforms = lib.platforms.linux;
    };
  });
in
{
  users.users.${username}.packages = [ d2launcher ];

  # wiped every boot under impermanence otherwise; holds the install, wineprefix, and saves
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".d2launcher"
  ];
}
