{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./steam.nix
  ];

  config = mkIf config.mySystem.features.gaming {
    # Hardware support for gaming
    hardware.steam-hardware.enable = mkIf config.mySystem.hardware.steam true;

    # Gaming programs
    programs = {
      gamescope.enable = true;
    };

    # Gaming applications
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      anki-bin
      lutris
      protonup-qt
      ryubing
      (wrapRetroArch {
        cores = with libretro; [
          nestopia
          bsnes
          mupen64plus
          gambatte
          mgba
          desmume
          genesis-plus-gx
          beetle-saturn
          flycast
          beetle-psx-hw
          pcsx2
          ppsspp
          mame
          fbneo
          stella
          beetle-pce-fast
        ];
      })
    ];
  };
}
