{inputs, ...}: {
  commonModules = [
    inputs.stylix.nixosModules.stylix
    inputs.cachyos.nixosModules.default
    ../configuration.nix
  ];
}
