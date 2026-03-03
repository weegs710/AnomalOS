{inputs, ...}: {
  flake.nixosModules.hjem-packages = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedHelium = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.helium;
    wrappedFastfetch = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fastfetch;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [
        pkgs.cryptomator
        pkgs.filen-desktop
        pkgs.filen-cli
        wrappedHelium
        wrappedFastfetch
      ];
    };
  };
}
