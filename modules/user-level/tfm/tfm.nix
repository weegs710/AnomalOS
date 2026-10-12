{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  sources = import ../../../_sources/generated.nix {
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
      runHook postInstall
    '';

    postFixup = ''
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/tfm

      wrapProgram $out/bin/tfm \
        --suffix PATH : ${lib.makeBinPath runtimeDeps} \
        --set-default TFM_FFMPEG ${pkgs.ffmpeg}/bin/ffmpeg
    '';

    meta = with lib; {
      description = "Mouse-driven terminal file manager";
      homepage = "https://github.com/clarkarch/tfm-tui";
      license = licenses.mit;
      mainProgram = "tfm";
      platforms = [ "x86_64-linux" ];
    };
  };

  # the terminal is called by name so the installed one wins, and kitty takes its command positionally with no -e
  chooserWrapper = pkgs.writeTextFile {
    name = "tfm-wrapper.nu";
    executable = true;
    text =
      lib.replaceStrings
        [
          "@NUSHELL@"
          "@TERM@"
          "@TFM@"
          "@CHOOSERCONF@"
        ]
        [
          "${pkgs.nushell}"
          "kitty"
          "${tfm}/bin/tfm"
          "${./chooser.toml}"
        ]
        (builtins.readFile ./tfm-wrapper.nu);
  };
in
{
  users.users.${username}.packages = [ tfm ];

  hjem.users.${username} = {
    xdg.config.files = {
      # the plugin loader lstats each entry and skips symlinks, so a linked .ts hashes to an empty folder and never loads
      "tfm/plugins/chooser/chooser.ts" = {
        source = ./plugins/chooser/chooser.ts;
        type = "copy";
      };
      "tfm/plugins/archive-extra/archive-extra.ts" = {
        source = ./plugins/archive-extra/archive-extra.ts;
        type = "copy";
      };

      "xdg-desktop-portal-termfilechooser/config".text =
        lib.replaceStrings [ "@WRAPPER@" ] [ "${chooserWrapper}" ]
          (builtins.readFile ./termfilechooser-config);
    };

    xdg.data.files."applications/tfm.desktop".source = ./tfm.desktop;
  };

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/tfm"
    ".local/state/tfm"
  ];
}
