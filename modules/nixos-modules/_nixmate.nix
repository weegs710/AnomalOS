{inputs, ...}: {
  flake.nixosModules.nixmate = {
    config,
    pkgs,
    ...
  }: {
    config = {
      users.users.${config.mySystem.user.name}.packages = [
        inputs.nixmate.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
