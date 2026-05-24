{ pkgs, ... }:
let
  relaxed-plymouth = pkgs.stdenvNoCC.mkDerivation {
    pname = "plymouth-relaxed";
    version = "1.0";

    src = pkgs.lib.fileset.toSource {
      root = ../..;
      fileset = pkgs.lib.fileset.unions [
        ../../docs/assets/relaxed.gif
        ../../scripts/plymouth
      ];
    };

    nativeBuildInputs = with pkgs; [
      ffmpeg
      imagemagick
      nushell
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      nu scripts/plymouth/build.nu
      runHook postInstall
    '';
  };
in
{
  boot.plymouth.theme = "relaxed";
  boot.plymouth.themePackages = [ relaxed-plymouth ];
}
