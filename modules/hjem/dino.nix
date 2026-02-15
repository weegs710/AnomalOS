{
  flake.nixosModules.dino = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [pkgs.dino];
      };
    };
}
