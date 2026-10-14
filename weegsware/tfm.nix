{ pkgs, lib, ... }:
let
  sources = import ../_sources/generated.nix {
    inherit (pkgs)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  # the archive table looks up `7z` by exact name and _7zz only ships a `7zz` binary
  sevenzip = pkgs.runCommand "tfm-7z-alias" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs._7zz}/bin/7zz $out/bin/7z
  '';

  runtimeDeps = [
    pkgs.glib.bin
    pkgs.util-linux
    pkgs.udisks
    pkgs.fd
    pkgs.wl-clipboard
    pkgs.xclip
    pkgs.imagemagick
    # magick shells out to `gs` by name for the pdf delegate
    pkgs.ghostscript_headless
    pkgs.xdg-utils
    pkgs.coreutils
    pkgs.gnutar
    pkgs.gzip
    pkgs.xz.bin
    pkgs.bzip2
    pkgs.zstd
    pkgs.lz4.out
    pkgs.lzip
    pkgs.brotli
    pkgs.lzop
    pkgs.ncompress
    pkgs.zip
    pkgs.unzip
    pkgs.libarchive
    sevenzip
    pkgs.git
  ];
in
{
  tfm = pkgs.stdenvNoCC.mkDerivation {
    inherit (sources.tfm) pname version src;

    dontUnpack = true;
    # the bun payload rides in the tail of the ELF, past the image fixupPhase would rewrite
    dontStrip = true;
    # an RPATH resolving the real glibc lib dir segfaults it; the interpreter alone is safe
    dontPatchELF = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.patchelf
      pkgs.python3
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      gzip -cd $src > $out/bin/tfm
      chmod +x $out/bin/tfm

      python3 ${./patch-appdirs.py} $out/bin/tfm
      python3 ${./patch-thumbcap.py} $out/bin/tfm
      python3 ${./patch-globs2.py} $out/bin/tfm
      python3 ${./patch-vdev-rows.py} $out/bin/tfm
      python3 ${./patch-pdf-thumbs.py} $out/bin/tfm
      runHook postInstall
    '';

    postFixup = ''
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/tfm

      wrapProgram $out/bin/tfm \
        --suffix PATH : ${lib.makeBinPath runtimeDeps} \
        --set-default TFM_FFMPEG ${pkgs.ffmpeg}/bin/ffmpeg \
        --set-default TFM_GLOBS2 ${pkgs.shared-mime-info}/share/mime/globs2
    '';

    meta = with lib; {
      description = "Mouse-driven terminal file manager";
      homepage = "https://github.com/clarkarch/tfm-tui";
      license = licenses.mit;
      mainProgram = "tfm";
      platforms = [ "x86_64-linux" ];
    };
  };
}
