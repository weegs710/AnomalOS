{ pkgs, ... }:
let
  # Built from source so nix owns the binary and plugins get a real python env; pinned to the 3.2.5-pre1 prerelease for the june 2026 steam-beta errorboundary fix
  # See: https://github.com/Jovian-Experiments/Jovian-NixOS/blob/master/pkgs/decky-loader/prerelease.nix
  decky-loader = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "decky-loader";
    version = "3.2.5-pre1";

    src = pkgs.fetchFromGitHub {
      owner = "SteamDeckHomebrew";
      repo = "decky-loader";
      rev = "v${version}";
      hash = "sha256-TTaDvpKzbSn14JPdMUqYppwnP/GmTc3p4PQY9y0QtmY=";
    };

    # pnpm-workspace.yaml confuses the pnpm fetcher and build
    postPatch = ''
      rm frontend/pnpm-workspace.yaml
    '';

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit pname version src;
      pnpm = pkgs.pnpm_9;
      fetcherVersion = 3;
      sourceRoot = "${src.name}/frontend";
      postPatch = ''
        rm pnpm-workspace.yaml
      '';
      hash = "sha256-WgKycKbaZv9lovoo0IaCuV41qS4zUqm4vZxsMQBUdNk=";
    };

    pyproject = true;
    pnpmRoot = "frontend";

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.pnpm_9
      pkgs.pnpmConfigHook
    ];

    preBuild = ''
      cd frontend
      pnpm build
      cd ../backend
    '';

    build-system = with pkgs.python3.pkgs; [
      poetry-core
      poetry-dynamic-versioning
    ];

    dependencies = with pkgs.python3.pkgs; [
      aiohttp
      aiohttp-cors
      aiohttp-jinja2
      certifi
      multidict
      packaging
      setproctitle
      watchdog
    ];

    # plugins shell out to these at runtime
    makeWrapperArgs = [
      "--prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.psmisc
        ]
      }"
    ];

    pythonRelaxDeps = [
      "aiohttp-cors"
      "packaging"
      "watchdog"
    ];

    meta = with pkgs.lib; {
      description = "Plugin loader for Steam Deck, built from source";
      homepage = "https://github.com/SteamDeckHomebrew/decky-loader";
      license = licenses.gpl2Only;
      platforms = platforms.linux;
    };
  };

  wrappedSteam =
    let
      base = pkgs.steam.override {
        extraPkgs = pkgs: [
          # Decky loader and its dependencies
          decky-loader
          pkgs.python3
          pkgs.curl
          pkgs.git
          pkgs.systemd
          pkgs.coreutils

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
    in
    base.overrideAttrs (old: {
      passthru = (old.passthru or { }) // {
        inherit decky-loader;
      };
    });
in
{
  steam = wrappedSteam;
}
