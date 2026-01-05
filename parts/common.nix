{inputs, ...}: {
  commonModules = [
    inputs.stylix.nixosModules.stylix
    inputs.agenix.nixosModules.default
    ../configuration.nix
  ];
}
