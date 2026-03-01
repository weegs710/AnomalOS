{
  perSystem = {pkgs, ...}: let
    aspell = pkgs.aspellWithDicts (d: [d.en]);

    endcordPkg = pkgs.stdenv.mkDerivation rec {
      pname = "endcord";
      version = "1.3.0";

      src = pkgs.fetchurl {
        url = "https://github.com/sparklost/endcord/releases/download/${version}/endcord-${version}-linux.tar.gz";
        hash = "sha256-A7WMO/gdaEk+2Yshb/KQw5+wFIkWy1oYjo3E27Xc704=";
      };

      sourceRoot = ".";
      dontBuild = true;
      dontConfigure = true;
      # nuitka onefile appends a zip payload after the ELF; patchelf and strip corrupt it
      dontStrip = true;
      dontPatchELF = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/share/doc/endcord
        install -m755 endcord $out/bin/endcord
        install -m644 README.md commands.md configuration.md extensions.md $out/share/doc/endcord/
        runHook postInstall
      '';

      meta = with pkgs.lib; {
        description = "Feature-rich TUI Discord client";
        homepage = "https://github.com/sparklost/endcord";
        license = licenses.gpl3Only;
        platforms = ["x86_64-linux"];
        mainProgram = "endcord";
      };
    };

    wrappedEndcord = pkgs.symlinkJoin {
      name = "endcord-wrapped";
      paths = [endcordPkg];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        # libpulse not on nix store path; portal xdg-open leaks dbus objectpaths into endcord UI
        wrapProgram $out/bin/endcord \
          --prefix PATH : ${pkgs.lib.makeBinPath [aspell]} \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [pkgs.libpulseaudio]} \
          --unset NIXOS_XDG_OPEN_USE_PORTAL
      '';
      meta.mainProgram = "endcord";
    };
  in {
    packages.endcord = wrappedEndcord;
  };
}
