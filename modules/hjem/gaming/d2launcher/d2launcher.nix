{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;

  # nixpkgs wine; the launcher's self-downloaded proton has no FHS loader on NixOS
  wine = pkgs.wineWow64Packages.stable;

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
    version = "4.1.3";

    src = pkgs.fetchFromGitHub {
      owner = "murkl";
      repo = "d2launcher";
      rev = finalAttrs.version;
      hash = "sha256-yK3ZYqeadh8AZ7q3TENdecAicGkBhSjZKlGUsBmzoMo=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/d2launcher
      cp -r res $out/share/d2launcher/res
      install -Dm755 d2launcher $out/bin/d2launcher

      # zenity is called by absolute path: the script's own zenity() wrapper function shadows the bare name and breaks command -v
      substituteInPlace $out/bin/d2launcher \
        --replace-fail '#!/usr/bin/env bash' '#!/usr/bin/env bash
      export PATH=${lib.makeBinPath runtimeDeps}:$PATH' \
        --replace-fail 'command -v /bin/zenity' 'command -v ${zenity}/bin/zenity' \
        --replace-fail '/usr/bin/zenity' '${zenity}/bin/zenity' \
        --replace-fail '/bin/notify-send' 'notify-send' \
        --replace-fail 'SCRIPT_RES_DIR="$WORKING_DIR/res"' 'SCRIPT_RES_DIR="'$out'/share/d2launcher/res"' \
        --replace-fail 'wine_default="$WINE_NATIVE_BIN"' 'wine_default="${wine}/bin/wine"' \
        --replace-fail 'wine_user="$WINE_NATIVE_USERNAME"' 'wine_user="$USER"'

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
