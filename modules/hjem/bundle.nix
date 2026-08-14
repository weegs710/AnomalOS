{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib.fileset) toList fileFilter difference;
  inherit (inputs.nixpkgs.lib) hasPrefix;
  modules = toList (
    difference (fileFilter (f: f.hasExt "nix" && f.name != "bundle.nix" && !(hasPrefix "_" f.name)) ./.) ./gaming
  );
in
{
  imports = [ inputs.hjem.nixosModules.default ] ++ modules;
  hjem.clobberByDefault = true;
}
