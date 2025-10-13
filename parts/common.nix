{inputs, ...}: {
  commonModules = [
    inputs.stylix.nixosModules.stylix
    inputs.cachyos.nixosModules.default
    inputs.agenix.nixosModules.default
    ../configuration.nix
  ];
}
