{
  flake.nixosModules.filen = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [
          pkgs.filen-desktop
          pkgs.filen-cli
        ];
      };
    };
}
