# Pure-tack entry point. Inputs come from ./.tack (no flake, no flake-parts).
# `nh os switch --file ./assemble.nix HX99G` builds HX99G.config.system.build.toplevel.
let
  inputs = import ./.tack;
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
  inherit (lib.fileset) toList fileFilter;

  weegsware = inputs.pkgs.packages.${system};

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
      inherit weegsware;
    };
    modules = moduleBundles ++ [
      ./modules/hosts/hx99g-hardware.nix
      ./modules/hosts/hx99g-zfs.nix
      ./modules/hosts/hx99g.nix
    ];
  };
}
