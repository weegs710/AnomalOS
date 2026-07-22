{ pkgs, ... }:
let
  # Built from source so nix owns the binary and plugins get a real python env; 3.2.6 is the stable release of the june 2026 steam-beta errorboundary fix
  # See: https://github.com/Jovian-Experiments/Jovian-NixOS/blob/master/pkgs/decky-loader/default.nix
  decky-loader = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "decky-loader";
    version = "3.2.6";

    src = pkgs.fetchFromGitHub {
      owner = "SteamDeckHomebrew";
      repo = "decky-loader";
      rev = "v${version}";
      hash = "sha256-p1bkLsZedTZ29POqdaXvVpPXzg9kBTKgUxkkEAyAkT0=";
    };

    # pnpm-workspace.yaml confuses the pnpm fetcher and build
    postPatch = ''
      rm frontend/pnpm-workspace.yaml
    '';

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit pname version src;
      # pnpm_9 is CVE-flagged in nixpkgs; 10.34.4 is clean and reads the v9 lockfile
      pnpm = pkgs.pnpm_10;
      fetcherVersion = 3;
      sourceRoot = "${src.name}/frontend";
      postPatch = ''
        rm pnpm-workspace.yaml
      '';
      hash = "sha256-X1L8JYG5hgYMmfg0aa8XhkRU6/oFrYTPiXDIyq77puE=";
    };

    pyproject = true;
    pnpmRoot = "frontend";

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.pnpm_10
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
