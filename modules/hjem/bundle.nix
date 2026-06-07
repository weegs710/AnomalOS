{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
  inherit (inputs.nixpkgs.lib) hasPrefix;
  modules = toList (
    fileFilter (f: f.hasExt "nix" && f.name != "bundle.nix" && !(hasPrefix "_" f.name)) ./.
  );
in
{
  imports = [ inputs.hjem.nixosModules.default ] ++ modules;
}
