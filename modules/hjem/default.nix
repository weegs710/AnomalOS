{ inputs, ... }: let
  inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
  inherit (inputs.nixpkgs.lib) hasPrefix;
  modules = toList (fileFilter (f: f.hasExt "nix" && f.name != "default.nix" && !(hasPrefix "_" f.name)) ./.);
in {
  flake.nixosModules.hjem = {
    imports = [ inputs.hjem.nixosModules.default ] ++ modules;
  };
}
