{
  perSystem = {pkgs, system, ...}: let
    # Use pkgs with unfree packages allowed for Steam
    pkgsUnfree = import pkgs.path {
      inherit system;
      config.allowUnfree = true;
    };

    # Decky-Loader derivation (moved from decky.nix)
    deckyVersion = "3.2.1";

    decky-loader = pkgs.stdenv.mkDerivation {
      pname = "decky-loader";
      version = deckyVersion;

      src = pkgs.fetchurl {
        url = "https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v${deckyVersion}/PluginLoader";
        hash = "sha256-LiqNn/zg8zdP3IvAW7dSgWiRjIPFvQccD8L61G5FAXc=";
      };

      dontUnpack = true;
      dontBuild = true;

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [
        pkgs.zlib
        pkgs.stdenv.cc.cc.lib
      ];

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/PluginLoader
        chmod +x $out/bin/PluginLoader
      '';

      meta = with pkgs.lib; {
        description = "Plugin loader for Steam Deck";
        homepage = "https://github.com/SteamDeckHomebrew/decky-loader";
        license = licenses.gpl2;
        platforms = platforms.linux;
      };

      passthru.updateScript = pkgs.writeShellScript "update-decky-loader" ''
        #!/usr/bin/env bash
        set -euo pipefail

        LATEST_VERSION=$(${pkgs.curl}/bin/curl -s https://api.github.com/repos/SteamDeckHomebrew/decky-loader/releases/latest | ${pkgs.jq}/bin/jq -r .tag_name | sed 's/^v//')

        HASH=$(${pkgs.nurl}/bin/nurl "https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v$LATEST_VERSION/PluginLoader" 2>&1 | grep -oP 'hash = "\K[^"]+')

        FILE="${toString ./.}/modules/shareables/wrapped-steam.nix"
        ${pkgs.gnused}/bin/sed -i "s/deckyVersion = \"[^\"]*\"/deckyVersion = \"$LATEST_VERSION\"/" "$FILE"
        ${pkgs.gnused}/bin/sed -i "s|hash = \"[^\"]*\"|hash = \"$HASH\"|" "$FILE" || \
        ${pkgs.gnused}/bin/sed -i "s|hash = lib.fakeHash|hash = \"$HASH\"|" "$FILE"

        echo "Updated Decky Loader to version $LATEST_VERSION with hash $HASH"
      '';
    };

    # Wrap Steam with Decky in FHS environment
    wrappedSteam = let
      base = pkgsUnfree.steam.override {
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
        passthru =
          (old.passthru or {})
          // {
            inherit decky-loader;
          };
      });
  in {
    packages.steam = wrappedSteam;
  };
}
