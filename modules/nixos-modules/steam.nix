{inputs, ...}: {
  flake.nixosModules.steam = {
    config,
    lib,
    pkgs,
    ...
  }: let
    wrappedSteam = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steam;
  in {
    config = lib.mkIf config.mySystem.features.gaming {
      users.users.${config.mySystem.user.name}.packages = [
        wrappedSteam
      ];

      environment.sessionVariables = {
        SDL_VIDEODRIVER = "wayland";
      };
    };
  };
}
