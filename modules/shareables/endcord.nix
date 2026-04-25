{
  perSystem =
    { pkgs, lib, ... }:
    let
      pathPkgs = [
        pkgs.wl-clipboard
        pkgs.yt-dlp
        pkgs.mpv
        (pkgs.aspellWithDicts (dicts: [ dicts.en ]))
      ];

      libPkgs = [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.ncurses
        # soundcard loads libpulse at runtime; PipeWire's pulse compat layer satisfies this.
        pkgs.pulseaudio
      ];

      endcordPkg = pkgs.stdenv.mkDerivation rec {
        pname = "endcord";
        version = "1.4.2";

        src = pkgs.fetchurl {
          url = "https://github.com/sparklost/endcord/releases/download/${version}/${pname}-${version}-linux.tar.gz";
          hash = "sha256-JceTyH4bP0PXX5vUpsRYAYMNUKkJN1TdJfEEVQpkqSc=";
        };

        # nix picks docs/ as sourceRoot without this since it's the only top-level directory.
        sourceRoot = ".";

        # nuitka onefile appends its payload after the ELF; strip regenerates the ELF without it.
        dontStrip = true;

        installPhase = ''
                  runHook preInstall
                  mkdir -p $out/bin

                  # tarball structure varies between releases.
                  # See: https://github.com/sparklost/endcord/blob/main/tools/install.sh
                  binary=$(find . -type f -name "endcord" | head -n 1)
                  cp "$binary" $out/bin/.endcord-wrapped
                  chmod +x $out/bin/.endcord-wrapped

                  cat > $out/bin/endcord << EOF
          #!${pkgs.bash}/bin/bash
          export PATH="${lib.makeBinPath pathPkgs}:\$PATH"
          export LD_LIBRARY_PATH="${lib.makeLibraryPath libPkgs}:\$LD_LIBRARY_PATH"
          exec $out/bin/.endcord-wrapped "\$@"
          EOF
                  chmod +x $out/bin/endcord

                  runHook postInstall
        '';

        meta = {
          description = "Feature rich Discord TUI client";
          homepage = "https://github.com/sparklost/endcord";
          platforms = [ "x86_64-linux" ];
          mainProgram = "endcord";
        };
      };
    in
    {
      packages.endcord = endcordPkg;
    };
}
