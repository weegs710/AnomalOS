{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
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
      desmume
      lutris
      ppsspp
      protonup-qt
      (retroarch.withCores (cores: with cores;
        # All cores except broken thepowdertoy
        lib.filter (core: core.pname or "" != "libretro-thepowdertoy") (lib.attrValues cores)
      ))
      ryubing
    ];
  };
}
