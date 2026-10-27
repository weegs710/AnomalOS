{ pkgs, ... }:
let
  millennium = pkgs.callPackage ./_millennium.nix {
    millennium-src = pkgs.fetchFromGitHub {
      owner = "Shochraos";
      repo = "Millennium";
      rev = "d4cd249aad050e2f68dfb4525ebf7b7544df7c68";
      hash = "sha256-2LrpdsL2nmsDVOkg34n4A6OqjpTdCOyhLc3yoHjII4o=";
    };
  };
in
{
  steam = pkgs.steam.override {
    extraArgs = "-nobigpicture";

    extraLibraries = pkgs: [
      millennium
      pkgs.pkgsi686Linux.openssl
      pkgs.openssl
    ];

    # Millennium reads these to find its libs from inside the FHS env
    extraEnv = {
      MILLENNIUM_RUNTIME_PATH = "${millennium}/lib/libmillennium_x86.so";
      MILLENNIUM_RUNTIME_PATH_X64 = "${millennium}/lib/libmillennium_x64.so";
    };

    # steam loads these as libXtst.so.6, which is how Millennium gets into the 32-bit, webhelper and 64-bit client processes
    extraProfile = ''
      ln -sf ${millennium}/lib/libmillennium_bootstrap_x86.so "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
      ln -sf ${millennium}/lib/libmillennium_bootstrap_hhx64.so "$HOME/.local/share/Steam/ubuntu12_64/libXtst.so.6"
      mkdir -p "$HOME/.local/share/Steam/steamrt64"
      ln -sf ${millennium}/lib/libmillennium_bootstrap_x64.so "$HOME/.local/share/Steam/steamrt64/libXtst.so.6"
    '';

    extraPkgs = pkgs: [
      # Gaming tools (for portability)
      pkgs.mangohud
      pkgs.gamescope
      pkgs.gamemode

      # Gamescope dependencies
      pkgs.libxcursor
      pkgs.libxi
      pkgs.libxinerama
      pkgs.libxscrnsaver
      pkgs.libpng
      pkgs.libpulseaudio
      pkgs.libvorbis
      pkgs.stdenv.cc.cc.lib
      pkgs.libkrb5
      pkgs.keyutils
    ];
  };
}
