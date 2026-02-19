{inputs, ...}: {
  flake.nixosModules.endcord = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedEndcord = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.endcord;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [wrappedEndcord];
    };
  };
}
