{inputs, ...}: {
  flake.nixosModules.hjem-packages = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedFastfetch = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fastfetch;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [
        wrappedFastfetch
      ];
    };
  };
}
