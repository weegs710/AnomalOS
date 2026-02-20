{inputs, ...}: {
  flake.nixosModules.oxicord = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [
        inputs.oxicord.packages.${pkgs.system}.default
      ];
    };
  };
}
