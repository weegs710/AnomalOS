{...}: {
  flake.nixosModules.dino = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      username = config.mySystem.user.name;
    in {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [pkgs.dino];
      };
    };
}
