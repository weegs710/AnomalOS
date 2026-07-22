# `nix-build ci.nix` builds everything; nonzero exit on any failure (the nix-flake-check analog).
let
  systems = (import ./assemble.nix { }).nixosConfigurations;
in
{
  HX99G = systems.HX99G.config.system.build.toplevel;
}
