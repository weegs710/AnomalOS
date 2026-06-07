# Pure-tack entry point. Inputs come from ./.tack (no flake, no flake-parts).
# `nh os switch --file ./assemble.nix HX99G` builds HX99G.config.system.build.toplevel.
let
  inputs = import ./.tack;
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
  inherit (lib.fileset) toList fileFilter;
  inherit (lib) hasPrefix;

  # One allowUnfree pkgs shared by every shareable -- avoids ~2s nixpkgs re-import per package.
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Shareables: discover leaf files, merge into a package set. `_`-prefix disables, autodiscovery stays.
  packages = lib.foldl' (acc: f: acc // import f { inherit pkgs inputs lib; }) { } (
    toList (fileFilter (f: f.hasExt "nix" && !(hasPrefix "_" f.name)) ./modules/shareables)
  );

  # Module bundles: every bundle.nix under modules/ (hjem, nixos-modules), each returns a NixOS module.
  moduleBundles = map (b: import b { inherit inputs; }) (
    toList (fileFilter (f: f.name == "bundle.nix") ./modules)
  );

  # Local-path cursor injected so xdg.nix's `inputs.fft-ivalice-cursor` is unchanged (copyright: stays out of the repo).
  inputs' = inputs // {
    fft-ivalice-cursor = /home/weegs/.local/share/cursor-sources/fft-ivalice-hyprcursor;
  };
in
{
  HX99G = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inputs = inputs';
      inherit packages;
    };
    modules = moduleBundles ++ [
      inputs.lix-module.nixosModules.default
      ./modules/hosts/hx99g-hardware.nix
      ./modules/hosts/hx99g-zfs.nix
      ./modules/hosts/hx99g.nix
    ];
  };
}
