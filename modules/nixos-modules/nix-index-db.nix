{inputs, ...}: {
  flake.nixosModules.nix-index-db = {
    imports = [inputs.nix-index-database.nixosModules.default];
    programs.nix-index-database.comma.enable = true;
  };
}
