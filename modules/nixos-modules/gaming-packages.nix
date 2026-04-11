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
      ];
    };
  };
}
