{inputs, ...}: {
  flake.nixosModules.hjem = {...}: {
    imports = [
      inputs.hjem.nixosModules.default
    ];
  };
}
