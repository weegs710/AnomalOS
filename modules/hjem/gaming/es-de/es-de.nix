{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedRetroArch = pkgs.wrapRetroArch {
    cores = with pkgs.libretro; [
      nestopia
      bsnes
      mupen64plus
      gambatte
      mgba
      melonds
      genesis-plus-gx
      picodrive
      beetle-saturn
      flycast
      beetle-psx-hw
      pcsx2
      ppsspp
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
    version = "3.4.1";
    src = pkgs.fetchurl {
      name = "ES-DE_x64.AppImage";
      url = "https://gitlab.com/es-de/emulationstation-de/-/package_files/288156961/download";
      sha256 = "109mfa3aag6x4gf08326cbgs09dl403ygvaqm8yicmcdfd6s8q9w";
    };
    extraPkgs = pkgs: [ ];
  };
in
{
  users.users.${username}.packages = [
    wrappedRetroArch
    esde
  ];

  hjem.users.${username} = {
    files = {
      "ES-DE/custom_systems/es_systems.xml".source = ./custom_systems/es_systems.xml;
      "ES-DE/custom_systems/es_find_rules.xml".text =
        lib.replaceStrings [ "@USER@" ] [ username ] (builtins.readFile ./custom_systems/es_find_rules.xml);
    };

    xdg.config.files = {
      # Nestopia (NES) - docs: https://docs.libretro.com/library/nestopia/
      "retroarch/config/Nestopia/Nestopia.opt".source = ./opts/nestopia.opt;

      # bsnes (SNES) - docs: https://docs.libretro.com/library/bsnes_accuracy/
      "retroarch/config/bsnes/bsnes.opt".source = ./opts/bsnes.opt;

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

      # Beetle Saturn - docs: https://docs.libretro.com/library/beetle_saturn/
      "retroarch/config/Beetle Saturn/Beetle Saturn.opt".source = ./opts/beetle-saturn.opt;

      # Flycast (Dreamcast) - docs: https://docs.libretro.com/library/flycast/
      "retroarch/config/Flycast/Flycast.opt".source = ./opts/flycast.opt;

      # Beetle PSX HW (PlayStation) - docs: https://docs.libretro.com/library/beetle_psx_hw/
      "retroarch/config/Beetle PSX HW/Beetle PSX HW.opt".source = ./opts/beetle-psx-hw.opt;

      # PCSX2 (PlayStation 2) - docs: https://docs.libretro.com/library/pcsx2/
      "retroarch/config/PCSX2/PCSX2.opt".source = ./opts/pcsx2.opt;

      # PPSSPP (PlayStation Portable) - docs: https://docs.libretro.com/library/ppsspp/
      "retroarch/config/PPSSPP/PPSSPP.opt".source = ./opts/ppsspp.opt;

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
  ];

  # ES-DE's default rom dir is ~/ROMs; symlink it to the collection so es_settings stays ES-DE-owned
  systemd.user.tmpfiles.rules = [
    "L+ %h/ROMs - - - - /mnt/games/1g1r/ROMs"
    # --set-shader paths resolve relative to the shader dir, so the slang pack lives here
    "L+ %h/.config/retroarch/shaders/shaders_slang - - - - ${pkgs.libretro-shaders-slang}/share/libretro/shaders/shaders_slang"
  ];
}
