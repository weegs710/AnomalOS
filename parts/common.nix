{inputs, ...}: {
  commonModules = [
    inputs.agenix.nixosModules.default
    ../configuration.nix
  ];
}
