{ inputs, ... }:
{ only, ... }:
let
  inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
  inherit (inputs.nixpkgs.lib) hasPrefix;
in
{
  imports = only.imports { tags = [ "server" ]; } (
    toList (fileFilter (f: f.hasExt "nix" && f.name != "bundle.nix" && !(hasPrefix "_" f.name)) ./.)
  );
}
