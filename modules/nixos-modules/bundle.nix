{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
  inherit (inputs.nixpkgs.lib) hasPrefix;
  modules = toList (
    fileFilter (f: f.hasExt "nix" && f.name != "bundle.nix" && !(hasPrefix "_" f.name)) ./.
  );
in
{
  # Prevents per-shareable nixpkgs re-imports for unfree -- each costs ~2s eval time
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };

  flake.nixosModules.nixos-modules = {
    imports = modules;
  };
}
