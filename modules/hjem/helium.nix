{inputs, ...}: {
  flake.nixosModules.helium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedHelium = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.helium;
  in {
      config = lib.mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [ wrappedHelium ];
      };
    };
}
