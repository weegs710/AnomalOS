# `nix-build ci.nix` builds everything; nonzero exit on any failure (the nix-flake-check analog).
let
  lib = (import ./.tack).nixpkgs.lib;
  outputs = import ./assemble.nix { };
in
# flattened to <system>-<host> so a host on a system this machine isn't gets checked instead of silently skipped
lib.concatMapAttrs (
  system: hosts: lib.mapAttrs' (host: drv: lib.nameValuePair "${system}-${host}" drv) hosts
) outputs.checks
