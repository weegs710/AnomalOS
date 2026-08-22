{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  appDir = "EltaleRecompiled";
  configDir = ".config/${appDir}";

  # N64Recomp reads the rom to generate the C, so it is a build input and not runtime-fed like the appimage ports
  baseRom = pkgs.requireFile {
    name = "quest64.us.z64";
    message = ''
      Eltale Recompiled only accepts the US N64 release.
      Add the dump to the store with
        nix-store --add-fixed sha256 quest64.us.z64
      See: https://dumping.guide/carts/nintendo/n64
    '';
    hash = "sha256-MpLZndk8MFSQaIeoSgDv3XR+5iDL6kYB3y9/gtX3THQ=";
  };

  michroma = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/main/ofl/michroma/Michroma-Regular.ttf";
    hash = "sha256-tiMBFjeIvFt/j8rAt0sYTjThgn5Xe0mey3JNoGUJj4c=";
  };

  src = pkgs.fetchFromGitHub {
    owner = "Rainchus";
    repo = "Quest64-Recomp";
    rev = "171ab8d5e0595d3b8f5886c7cb45361c73930c32";
    hash = "sha256-S+6ctX7yM6F3/0paoipRFL8fCasK/L8yQQTlExwkgMY=";
  };

  # .gitmodules points N64ModernRuntime and sf64decomp at sonicdcer, whose repos return 404, so submodules are assembled by hand
  quest64Syms = pkgs.fetchFromGitHub {
    owner = "Rainchus";
    repo = "Quest64Syms";
    rev = "46254e8f90d5e3779f575c7c99565bf159b709a2";
    hash = "sha256-ZmCg/NRWzNmBRW8G8NPTn2RznJo6UT+zp570kPLp7BI=";
  };

  # stands in for the dead sf64decomp, which the patches lib only ever needed for libultra headers
  quest64Decomp = pkgs.fetchFromGitHub {
    owner = "Rainchus";
    repo = "Quest64-Decomp";
    rev = "d964ce0f1be3f5e7789e6cc97c4878a9529f6aac";
    hash = "sha256-/V9NtDzIqrDxK7XOtlYQFk1gygf5m1+ycv20S19dkow=";
  };

  n64ModernRuntime = pkgs.fetchFromGitHub {
    owner = "N64Recomp";
    repo = "N64ModernRuntime";
    rev = "212c0cd304862b961f0bb0a9a3ed1ca045ed8358";
    hash = "sha256-mwkKP+VRwCJSoUurSP3fnENSRvYZkZkl0l3zWggbdus=";
    fetchSubmodules = true;
  };

  rt64 = pkgs.fetchFromGitHub {
    owner = "rt64";
    repo = "rt64";
    rev = "aa047b8158034552466175b8e8554988caa18976";
    hash = "sha256-Jc47Hr4R3GLCPXzPR7Z7T+MMi0aaZcF3kK1FmjA6cl0=";
    fetchSubmodules = true;
  };

  rmlui = pkgs.fetchFromGitHub {
    owner = "mikke89";
    repo = "RmlUi";
    rev = "7a06f27db04fe5d13a5dacc19b2b4544673a4eca";
    hash = "sha256-aBu97ZugJIfJTYFpgDYC/OU+pX/fe9ne4PsTG01mWIM=";
  };

  lunasvg = pkgs.fetchFromGitHub {
    owner = "sammycage";
    repo = "lunasvg";
    rev = "4166d0cccfc059b39d5ecfc372524375e59448f9";
    hash = "sha256-U/ohYe5j/c7bGvEFkEHZPggdzt6vu9ThnzVgECG8AWk=";
  };

  sse2neon = pkgs.fetchFromGitHub {
    owner = "DLTcollab";
    repo = "sse2neon";
    rev = "706d3b58025364c2371cafcf9b16e32ff7e630ed";
    hash = "sha256-jeaGP6j/ML6W+ls1ZKUQHWy4gXqkIrV3V918+YIDoXY=";
  };

  freetypeWindows = pkgs.fetchFromGitHub {
    owner = "ubawurinna";
    repo = "freetype-windows-binaries";
    rev = "d6fb49d11a9d0011bf4ecfe7e570beaaa189838a";
    hash = "sha256-rk+D+bv84yCS9fBv3ZpMqgUwsAzz9wa/TiLoWyhI3f0=";
  };

  dxcRunpath = lib.makeLibraryPath (with pkgs; [
    stdenv.cc.cc.lib
    zlib
    glibc
  ]);

  eltale-recomp = pkgs.llvmPackages_19.stdenv.mkDerivation {
    pname = "eltale-recomp";
    version = "0.1-unstable-2026-01-17";
    inherit src;

    strictDeps = true;

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      pkg-config
      gnumake
      llvmPackages_19.lld
      makeWrapper
      patchelf
      wrapGAppsHook3
    ];

    buildInputs = with pkgs; [
      SDL2
      freetype
      gtk3
      vulkan-loader
      libGL
      libx11
      libxrandr
      libxi
      libxcursor
    ];

    # the upstream tarball ships every submodule path as an empty directory, so the copies must replace them rather than land inside
    postUnpack = ''
      cp -rT ${quest64Syms}      source/Quest64Syms
      cp -rT ${quest64Decomp}    source/lib/quest64decomp
      cp -rT ${n64ModernRuntime} source/lib/N64ModernRuntime
      cp -rT ${rt64}             source/lib/rt64
      cp -rT ${rmlui}            source/lib/RmlUi
      cp -rT ${lunasvg}          source/lib/lunasvg
      cp -rT ${sse2neon}         source/lib/sse2neon
      cp -rT ${freetypeWindows}  source/lib/freetype-windows-binaries

      # the copies keep store modes so rt64's prebuilt dxc stays executable, so write access has to be granted separately
      chmod -R u+w source
    '';

    patches = [ ./patch-eltale-recomp ];

    postPatch = ''
      patch -p1 -d lib/rt64 < ${./patch-rt64}
      patch -p1 -d lib/N64ModernRuntime < ${./patch-n64modernruntime}

      # rt64 compiles its shaders with a prebuilt glibc dxc, whose interpreter only resolves outside the sandbox via nix-ld
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} \
               --set-rpath ${dxcRunpath} \
               lib/rt64/src/contrib/dxc/bin/x64/dxc-linux
      patchelf --set-rpath ${dxcRunpath} \
               lib/rt64/src/contrib/dxc/lib/x64/libdxcompiler.so \
               lib/rt64/src/contrib/dxc/lib/x64/libdxil.so

      # patches/print.c includes libc/stdarg.h, which the Quest 64 decomp keeps at 2.0H/stdarg.h instead
      mkdir -p patches/shim_headers/libc
      echo '#include <stdarg.h>' > patches/shim_headers/libc/stdarg.h

      cp ${michroma} assets/Michroma-Regular.ttf

      # leftovers from the Star Fox 64 fork this was built from, none of them reachable in a Quest 64 build
      rm -rf mods DOCS/fox_lore.md assets/mm-clipped.svg .github/linux/Starfox64Recompiled.desktop
    '';

    preConfigure = ''
      ln -s ${baseRom} ./quest64.us.z64
      cp ${pkgs.n64recomp}/bin/N64Recomp ${pkgs.n64recomp}/bin/RSPRecomp .

      ./N64Recomp us.rev0.toml
      ./RSPRecomp aspMain.toml
    '';

    # the Makefile's LD ?= ld.lld loses to the stdenv LD, which cannot link mips objects
    cmakeFlags = [
      "-DPATCHES_C_COMPILER=clang"
      "-DPATCHES_LD=ld.lld"
    ];

    hardeningDisable = [
      "format"
      "pic"
      "stackprotector"
      "zerocallusedregs"
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 EltaleRecompiled $out/bin/EltaleRecompiled
      install -Dm644 ../recompcontrollerdb.txt $out/share/recompcontrollerdb.txt
      install -Dm644 ../icons/512.png $out/share/icons/hicolor/512x512/apps/eltale-recomp.png
      cp -r ../assets $out/share/
      ln -s $out/share/recompcontrollerdb.txt $out/bin/recompcontrollerdb.txt
      ln -s $out/share/assets $out/bin/assets

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.vulkan-loader ]}
      )
    '';

    # the binary resolves assets/ relative to the cwd
    postFixup = ''
      wrapProgram $out/bin/EltaleRecompiled --chdir "$out/bin/"
    '';

    meta = {
      description = "Eltale Recompiled -- Quest 64 statically recompiled, Star Fox 64 leftovers trimmed, widescreen overlay fix";
      homepage = "https://github.com/Rainchus/Quest64-Recomp";
      license = with lib.licenses; [
        gpl3Only
        mit
        unfree
      ];
      mainProgram = "EltaleRecompiled";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  users.users.${username}.packages = [ eltale-recomp ];

  hjem.users.${username}.xdg.config.files = {
    "${appDir}/graphics.json".source = ./graphics.json;
    "${appDir}/controls.json".source = ./controls.json;
    "${appDir}/general.json".source = ./general.json;
    "${appDir}/sound.json".source = ./sound.json;
  };

  # the four json files are hjem-owned and re-laid each boot, so they stay out of the persist list
  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      "${configDir}/saves"
    ];
    files = [
      "${configDir}/quest64_us.z64"
      "${configDir}/launcher-bg.png"
      "${configDir}/manual.pdf"
      "${configDir}/strategy-guide.pdf"
    ];
  };
}
