{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  # upstream melonds ships an executable-stack .so (GNU_STACK RWE) this host refuses to dlopen; force noexec so retroarch can load the DS core
  melondsFixed = pkgs.libretro.melonds.overrideAttrs (old: {
    NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " -z noexecstack";
  });
  # ffmpeg here only backs retroarch's own recorder and media-player core, and ffmpeg_7 carries unfixed CVEs
  retroarchBare = pkgs.retroarch-bare.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [ "--disable-ffmpeg" ];
    buildInputs = lib.filter (d: (d.pname or "") != "ffmpeg") old.buildInputs;
  });
  # stock cores ship a retroarch-<core> launcher pinned to stock retroarch-bare, so only their .so is kept
  coreOnly =
    core:
    pkgs.runCommand "${core.name}-core" { passthru = { inherit (core) core libretroCore; }; } ''
      mkdir -p $out${core.libretroCore}
      cp ${core}${core.libretroCore}/* $out${core.libretroCore}/
    '';
  # the wrapper closes over its own retroarch-bare argument, so it is taken from an override that swaps it
  wrapRetroArch =
    args:
    (pkgs.retroarch-bare.override { retroarch-bare = retroarchBare; }).wrapper (
      args // { cores = map coreOnly args.cores; }
    );
  wrappedRetroArch = wrapRetroArch {
    cores = with pkgs.libretro; [
      fceumm
      snes9x
      mupen64plus
      gambatte
      mgba
      melondsFixed
      genesis-plus-gx
      picodrive
      stella
      beetle-pce-fast
      beetle-supergrafx
      atari800
      prosystem
      handy
      virtualjaguar
      hatari
      beetle-vb
      gw
      pokemini
      beetle-ngp
      beetle-wswan
      bluemsx
      vice-x64
      vice-xplus4
      vice-xvic
      puae
      freeintv
      vecx
      o2em
      np2kai
      fuse
    ];
  };

  esde = pkgs.appimageTools.wrapType2 {
    pname = "es-de";
    version = "3.5.0";
    src = pkgs.fetchurl {
      name = "ES-DE_x64.AppImage";
      url = "https://gitlab.com/es-de/emulationstation-de/-/package_files/357718352/download";
      sha256 = "1x9h6qycz0y7wh97q7vryffvcxhwi7x8dyfkbdvqaprq2ad9khmb";
    };
    # nixpkgs dropped libgpg-error from the appimage defaults (3b5bba1a98) and AppRun links it
    extraPkgs = p: [ p.libgpg-error ];
  };

  # flat display makes crt-geom's default barrel curvature read as distortion, not CRT
  mameBgfxFlat = pkgs.runCommand "mame-bgfx-flat" { } ''
    cp -rs ${pkgs.mame}/opt/mame/bgfx $out
    chmod -R u+w $out
    rm $out/chains/crt-geom.json
    ${pkgs.jq}/bin/jq '(.sliders[] | select(.name == "curvature" or .name == "cornersize")).default = 0.0' \
      ${pkgs.mame}/opt/mame/bgfx/chains/crt-geom.json > $out/chains/crt-geom.json
  '';
in
{
  users.users.${username}.packages = [
    wrappedRetroArch
    esde
    pkgs.mame
    pkgs.azahar
    # ES-DE's RYUJINX rule searches PATH for a binary named Ryujinx, which is ryubing's
    pkgs.ryubing
  ];

  hjem.users.${username} = {
    files = {
      "ES-DE/custom_systems/es_systems.xml".source = ./custom_systems/es_systems.xml;
      "ES-DE/custom_systems/es_find_rules.xml".text = lib.replaceStrings [ "@USER@" ] [ username ] (
        builtins.readFile ./custom_systems/es_find_rules.xml
      );

      ".mame/mame.ini".text = ''
        video                bgfx
        bgfx_screen_chains   crt-geom
        bgfx_path            ${mameBgfxFlat}
        mouse                1
        lightgun             1
        lightgun_device      mouse
      '';
    };

    xdg.config.files = {

      # FCEUmm (NES) - docs: https://docs.libretro.com/library/fceumm/
      "retroarch/config/FCEUmm/FCEUmm.opt".source = ./opts/fceumm.opt;

      # Snes9x (SNES) - docs: https://docs.libretro.com/library/snes9x/
      "retroarch/config/Snes9x/Snes9x.opt".source = ./opts/snes9x.opt;

      # Mupen64Plus-Next (N64) - docs: https://docs.libretro.com/library/mupen64plus/
      "retroarch/config/Mupen64Plus-Next/Mupen64Plus-Next.opt".source = ./opts/mupen64plus-next.opt;

      # Gambatte (Game Boy/Color) - docs: https://docs.libretro.com/library/gambatte/
      "retroarch/config/Gambatte/Gambatte.opt".source = ./opts/gambatte.opt;

      # mGBA (Game Boy Advance) - docs: https://docs.libretro.com/library/mgba/
      "retroarch/config/mGBA/mGBA.opt".source = ./opts/mgba.opt;

      # melonDS (Nintendo DS / DSi) - docs: https://docs.libretro.com/library/melonds/
      "retroarch/config/melonDS/melonDS.opt".source = ./opts/melonds.opt;

      # Genesis Plus GX (Genesis/CD/32X) - docs: https://docs.libretro.com/library/genesis_plus_gx/
      "retroarch/config/Genesis Plus GX/Genesis Plus GX.opt".source = ./opts/genesis-plus-gx.opt;

      # Stella (Atari 2600) - docs: https://docs.libretro.com/library/stella/
      "retroarch/config/Stella/Stella.opt".source = ./opts/stella.opt;

      # Beetle PCE Fast (TurboGrafx-16) - docs: https://docs.libretro.com/library/beetle_pce_fast/
      "retroarch/config/Beetle PCE Fast/Beetle PCE Fast.opt".source = ./opts/beetle-pce-fast.opt;
    };
  };

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/retroarch"
    "ES-DE/settings"
    "ES-DE/gamelists"
    "ES-DE/downloaded_media"
    "ES-DE/collections"
    "ES-DE/themes"
    "ES-DE/controllers"
    ".mame"
    ".config/azahar-emu"
    ".config/Ryujinx"
    # azahar keys save paths on program id, not install state, so rom-booted titles save here too
    ".local/share/azahar-emu"
  ];

  # ES-DE's default rom dir is ~/ROMs; symlink it to the collection so es_settings stays ES-DE-owned
  systemd.user.tmpfiles.users.${username}.rules = [
    "L+ %h/ROMs - - - - ${config.mySystem.paths.games}/1g1r/ROMs"
    # --set-shader paths resolve relative to the shader dir, so the slang pack lives here
    "L+ %h/.config/retroarch/shaders/shaders_slang - - - - ${pkgs.libretro-shaders-slang}/share/libretro/shaders/shaders_slang"
  ];
}
