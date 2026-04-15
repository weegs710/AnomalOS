{inputs, ...}: {
  flake.nixosModules.hjem-packages = {
    config,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedFastfetch = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fastfetch;
    wrappedZen = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zen;
  in {
    users.users.${username}.packages = [
      wrappedFastfetch
      wrappedZen
    ];
  };
}
