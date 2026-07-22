# Fetched as a prebuilt binary; source is kept private
{ pkgs, ... }:
{
  gorguru = pkgs.stdenv.mkDerivation {
    pname = "gorguru";
    version = "0.1.0";
    src = pkgs.fetchurl {
      url = "https://weegs.dev/dist/gorguru";
      hash = "sha256-laE+NFvZVOyHbR2kTp4QEOCeN6Ixj0+JJpPYRl18zN0=";
    };
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/gorguru
      chmod +x $out/bin/gorguru
    '';
  };
}
