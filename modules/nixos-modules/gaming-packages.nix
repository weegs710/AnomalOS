{
  flake.nixosModules.gaming-packages = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.gaming {
        programs.nix-ld.enable = true;

        hardware.steam-hardware.enable = lib.mkIf config.mySystem.hardware.steam true;

        programs = {
          gamescope.enable = true;
        };

        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          openraPackages.engines.bleed
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
    };
}
