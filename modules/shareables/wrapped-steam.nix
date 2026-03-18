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

      passthru.updateScript = pkgs.writeTextFile {
        name = "update-decky-loader";
        executable = true;
        text = ''
          #!${pkgs.nushell}/bin/nu

          let version = http get "https://api.github.com/repos/SteamDeckHomebrew/decky-loader/releases/latest"
            | get tag_name
            | str replace --regex '^v' ""

          let url = $"https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v($version)/PluginLoader"
          let hash = (^${pkgs.nurl}/bin/nurl $url
            | lines
            | where { |l| $l | str contains 'hash = "' }
            | first
            | str trim
            | parse 'hash = "{hash}";'
            | get hash
            | first)

          let file = $"($nu.home-path)/dotfiles/modules/shareables/wrapped-steam.nix"
          open --raw $file
            | str replace --regex 'deckyVersion = "[^"]*"' $'deckyVersion = "($version)"'
            | str replace --regex 'hash = (?:"[^"]*"|lib\.fakeHash)' $'hash = "($hash)"'
            | save --force $file

          print $"Updated Decky Loader to ($version) with hash ($hash)"
        '';
      };
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
