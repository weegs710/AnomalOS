{inputs, ...}: {
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
          gamemode.enable = true;
        };

        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          inputs.severed-chains.packages.${pkgs.stdenv.hostPlatform.system}.default
          (openraPackages.engines.bleed.overrideAttrs (old: {
            postPatch = "";
          }))
          heroic
          protonup-qt
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
