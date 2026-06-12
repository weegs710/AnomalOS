{
  config,
  pkgs,
  inputs,
  weegsware,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedRetroArch = weegsware.retroarch;
in
{
  users.users.${username}.packages = [ wrappedRetroArch ];

  hjem.users.${username} = {
    xdg.config.files = {
      # Nestopia (NES) - docs: https://docs.libretro.com/library/nestopia/
      "retroarch/config/Nestopia UE/Nestopia UE.opt".source = ./opts/nestopia.opt;

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
  ];
}
